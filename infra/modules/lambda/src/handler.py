import boto3
import json
import uuid
import os
from datetime import datetime, timezone, timedelta

s3     = boto3.client("s3")
dynamo = boto3.resource("dynamodb")

BUCKET     = os.environ["BUCKET_NAME"]
TABLE_NAME = os.environ["DYNAMODB_TABLE"]
URL_EXPIRY = int(os.environ.get("URL_EXPIRY_SECONDS", "3600"))


def handler(event, context):
    # Récupérer la clé du fichier depuis l'URL
    file_key = event.get("pathParameters", {}).get("file_key")

    if not file_key:
        return {
            "statusCode": 400,
            "body": json.dumps({"erreur": "file_key manquant"})
        }

    # Générer l'URL pré-signée S3
    try:
        url = s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": BUCKET, "Key": file_key},
            ExpiresIn=URL_EXPIRY
        )
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"erreur": str(e)})
        }

    # Enregistrer la trace dans DynamoDB
    now   = datetime.now(timezone.utc)
    table = dynamo.Table(TABLE_NAME)
    table.put_item(Item={
        "download_id": str(uuid.uuid4()),
        "file_key":    file_key,
        "requested_at": now.isoformat(),
        "client_ip":   event.get("requestContext", {}).get("identity", {}).get("sourceIp", "inconnu"),
        "url_expiry":  (now + timedelta(seconds=URL_EXPIRY)).isoformat(),
        "expires_at":  int((now + timedelta(days=90)).timestamp())
    })

    return {
        "statusCode": 200,
        "headers": {"Access-Control-Allow-Origin": "*"},
        "body": json.dumps({"download_url": url, "expires_in": URL_EXPIRY})
    }
