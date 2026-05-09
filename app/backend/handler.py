import json
import boto3
import re
import uuid
import logging
import os
from datetime import datetime, timezone
# IMPORT MANQUANT ICI :
from botocore.config import Config

# Configuration du logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Clients AWS avec Signature V4 forcée pour eu-west-3 (Paris)
s3_config = Config(
    signature_version='s3v4',
    region_name='eu-west-3'
)
s3_client = boto3.client("s3", config=s3_config)
dynamodb = boto3.resource("dynamodb", region_name='eu-west-3') # Précise aussi la région ici

# Variables d'environnement
BUCKET_NAME = os.environ["BUCKET_NAME"]
TABLE_NAME = os.environ["DYNAMODB_TABLE"]
URL_EXPIRY = int(os.environ.get("URL_EXPIRY", 3600))

def validate_file_id(file_id: str) -> bool:
    if not file_id or len(file_id) > 200:
        return False
    if ".." in file_id or file_id.startswith("/"):
        return False
    pattern = r'^[a-zA-Z0-9\-_\./]+$'
    return bool(re.match(pattern, file_id))

def file_exists_in_s3(file_id: str) -> bool:
    try:
        s3_client.head_object(Bucket=BUCKET_NAME, Key=file_id)
        return True
    except Exception:
        return False

def generate_presigned_url(file_id: str) -> str:
    filename = file_id.split('/')[-1]
    return s3_client.generate_presigned_url(
        ClientMethod="get_object",
        Params={
            "Bucket": BUCKET_NAME, 
            "Key": file_id,
            "ResponseContentDisposition": f"attachment; filename=\"{filename}\""
        },
        ExpiresIn=URL_EXPIRY
    )

def write_audit_record(file_id: str, request_id: str, ip_source: str, status: str):
    table = dynamodb.Table(TABLE_NAME)
    table.put_item(Item={
        "download_id": request_id,
        "FileID": file_id,
        "Timestamp": datetime.now(timezone.utc).isoformat(),
        "IPSource": ip_source,
        "Status": status
    })

def handler(event, context):
    request_id = str(uuid.uuid4())
    ip_source = event.get("requestContext", {}).get("identity", {}).get("sourceIp", "unknown")

    path_params = event.get("pathParameters") or {}
    file_id = path_params.get("file_key", "").strip()

    if not file_id:
        query_params = event.get("queryStringParameters") or {}
        file_id = query_params.get("file_id", "").strip()

    logger.info(f"[{request_id}] Requête pour file_id='{file_id}'")

    if not validate_file_id(file_id):
        write_audit_record(file_id, request_id, ip_source, "DENIED")
        return {
            "statusCode": 400,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": "FileID invalide."})
        }

    if not file_exists_in_s3(file_id):
        write_audit_record(file_id, request_id, ip_source, "NOT_FOUND")
        return {
            "statusCode": 404,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": "Fichier introuvable."})
        }

    try:
        presigned_url = generate_presigned_url(file_id)
        write_audit_record(file_id, request_id, ip_source, "SUCCESS")
        return {
            "statusCode": 200,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"download_url": presigned_url})
        }
    except Exception as e:
        logger.error(f"Erreur: {e}")
        return {
            "statusCode": 500,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": "Erreur interne."})
        }
