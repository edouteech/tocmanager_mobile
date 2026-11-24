#!/usr/bin/env bash
set -euo pipefail

# Automated PostgreSQL custom backup with optional OpenSSL encryption and upload to Cloudflare R2 / S3.
# Usage: DATABASE_URL=postgresql://... S3_BUCKET=... S3_ACCESS_KEY_ID=... S3_SECRET_ACCESS_KEY=... ./backup_pg_to_s3.sh

: "${DATABASE_URL:?DATABASE_URL must be set}"
: "${S3_BUCKET:?S3_BUCKET must be set}"
: "${S3_ACCESS_KEY_ID:?S3_ACCESS_KEY_ID must be set}"
: "${S3_SECRET_ACCESS_KEY:?S3_SECRET_ACCESS_KEY must be set}"

RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"
STAMP="$(date -u +%Y%m%d_%H%M%S)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

RAW_FILE="$TMP_DIR/tocmanager_${STAMP}.dump"
UPLOAD_FILE="$RAW_FILE"
OBJECT_EXT="dump"

pg_dump --format=custom --no-owner --no-privileges --dbname="$DATABASE_URL" --file="$RAW_FILE"

if [ -n "${BACKUP_ENCRYPTION_PASSPHRASE:-}" ]; then
  UPLOAD_FILE="${RAW_FILE}.enc"
  OBJECT_EXT="dump.enc"
  openssl enc -aes-256-cbc -pbkdf2 -salt -in "$RAW_FILE" -out "$UPLOAD_FILE" -pass env:BACKUP_ENCRYPTION_PASSPHRASE
fi

export BACKUP_UPLOAD_FILE="$UPLOAD_FILE"
export BACKUP_OBJECT_KEY="backups/postgresql/tocmanager_${STAMP}.${OBJECT_EXT}"
export BACKUP_RETENTION_DAYS="$RETENTION_DAYS"

python3 - <<'PY'
from datetime import datetime, timedelta, timezone
import os
import boto3

client = boto3.client(
    "s3",
    endpoint_url=os.getenv("S3_ENDPOINT_URL") or None,
    region_name=os.getenv("S3_REGION", "auto"),
    aws_access_key_id=os.environ["S3_ACCESS_KEY_ID"],
    aws_secret_access_key=os.environ["S3_SECRET_ACCESS_KEY"],
)

bucket = os.environ["S3_BUCKET"]
key = os.environ["BACKUP_OBJECT_KEY"]
client.upload_file(os.environ["BACKUP_UPLOAD_FILE"], bucket, key)

cutoff = datetime.now(timezone.utc) - timedelta(days=int(os.environ["BACKUP_RETENTION_DAYS"]))
paginator = client.get_paginator("list_objects_v2")
for page in paginator.paginate(Bucket=bucket, Prefix="backups/postgresql/"):
    for obj in page.get("Contents", []):
        if obj["LastModified"] < cutoff:
            client.delete_object(Bucket=bucket, Key=obj["Key"])

print(f"Backup uploaded to s3://{bucket}/{key}")
PY
