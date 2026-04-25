import json
import boto3
import re
import uuid
import logging
import os
from datetime import datetime, timezone

# Configuration du logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Clients AWS
s3_client = boto3.client("s3")
dynamodb  = boto3.resource("dynamodb")

# Variables d'environnement définies dans Terraform
BUCKET_NAME = os.environ["BUCKET_NAME"]
TABLE_NAME  = os.environ["DYNAMODB_TABLE"]
URL_EXPIRY  = int(os.environ.get("URL_EXPIRY", 3600))


def validate_file_id(file_id: str) -> bool:
    """Vérifie que le FileID est sûr — pas de path traversal, caractères autorisés uniquement."""
    if not file_id or len(file_id) > 200:
        return False
    if ".." in file_id or file_id.startswith("/"):
        return False
    pattern = r'^[a-zA-Z0-9\-_\./]+$'
    return bool(re.match(pattern, file_id))


def file_exists_in_s3(file_id: str) -> bool:
    """Vérifie que le fichier existe dans S3."""
    try:
        s3_client.head_object(Bucket=BUCKET_NAME, Key=file_id)
        return True
    except Exception:
        return False

def generate_presigned_url(file_id: str) -> str:
    """Génère une URL présignée S3 forçant le téléchargement et valable 1h."""
    
    # On extrait le nom du fichier pour qu'il garde son nom d'origine au téléchargement
    filename = file_id.split('/')[-1]
    
    return s3_client.generate_presigned_url(
        ClientMethod="get_object",
        Params={
            "Bucket": BUCKET_NAME, 
            "Key": file_id,
            # CETTE LIGNE FORCE LE TÉLÉCHARGEMENT SUR LE PC :
            "ResponseContentDisposition": f"attachment; filename=\"{filename}\""
        },
        ExpiresIn=URL_EXPIRY # Utilise bien tes 3600 secondes (1h)
    )


def write_audit_record(file_id: str, request_id: str, ip_source: str, status: str):
    """Enregistre chaque accès dans DynamoDB."""
    table = dynamodb.Table(TABLE_NAME)
    table.put_item(Item={
        "download_id": request_id,
        "FileID":    file_id,
        "Timestamp": datetime.now(timezone.utc).isoformat(),
        "IPSource":  ip_source,
        "Status":    status
    })


def handler(event, context):
    """
    Point d'entrée de la Lambda — appelée par API Gateway.
    Route : GET /fichiers/{file_key}
    """
    request_id = str(uuid.uuid4())
    ip_source  = event.get("requestContext", {}).get("identity", {}).get("sourceIp", "unknown")

    # ── Récupération du file_id depuis pathParameters ──
    path_params = event.get("pathParameters") or {}
    file_id     = path_params.get("file_key", "").strip()

    # Si pas dans pathParameters, essayer queryStringParameters
    if not file_id:
        query_params = event.get("queryStringParameters") or {}
        file_id      = query_params.get("file_id", "").strip()

    logger.info(f"[{request_id}] Requête pour file_id='{file_id}' depuis IP={ip_source}")

    # ── Étape 1 : Validation ──
    if not validate_file_id(file_id):
        write_audit_record(file_id, request_id, ip_source, "DENIED")
        return {
            "statusCode": 400,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"error": "FileID invalide."})
        }

    # ── Étape 2 : Vérification S3 ──
    if not file_exists_in_s3(file_id):
        write_audit_record(file_id, request_id, ip_source, "NOT_FOUND")
        return {
            "statusCode": 404,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"error": "Fichier introuvable."})
        }

    # ── Étape 3 : Génération URL présignée ──
    try:
        presigned_url = generate_presigned_url(file_id)
    except Exception as e:
        logger.error(f"[{request_id}] Erreur : {e}")
        write_audit_record(file_id, request_id, ip_source, "ERROR")
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"error": "Erreur interne."})
        }

    # ── Étape 4 : Audit succès ──
    write_audit_record(file_id, request_id, ip_source, "SUCCESS")
    logger.info(f"[{request_id}] URL générée pour '{file_id}'")

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        },
        "body": json.dumps({
            "file_id":      file_id,
            "download_url": presigned_url,
            "expires_in":   URL_EXPIRY
        })
    }
