# Runbook Sauvegarde et Restauration PostgreSQL (Cloudflare R2 / S3)

## 1. Sauvegarde automatisee (`backup_pg_to_s3.sh`)

Prerequis sur l'hote / conteneur de sauvegarde : `pg_dump` (PostgreSQL 16), `openssl`, `python3` avec `boto3`.

Variables d'environnement requises :
- `DATABASE_URL` : URL PostgreSQL (`postgresql://user:pass@host:5432/tocmanager`)
- `S3_ENDPOINT_URL` : Endpoint Cloudflare R2 (`https://<account-id>.r2.cloudflarestorage.com`)
- `S3_REGION` : `auto` (R2) ou region AWS
- `S3_BUCKET`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`
- Optionnel : `BACKUP_ENCRYPTION_PASSPHRASE` (active le chiffrement AES-256-CBC PBKDF2)
- Optionnel : `BACKUP_RETENTION_DAYS` (defaut `30` jours)

Exemple cron quotidien a 02h00 UTC :
```cron
0 2 * * * /app/scripts/backup_pg_to_s3.sh >> /var/log/tocmanager_backup.log 2>&1
```

## 2. Procedure de restauration

1. Telecharger l'archive depuis Cloudflare R2 vers un fichier local (`tocmanager.dump` ou `tocmanager.dump.enc`).
2. Si l'archive est chiffree (`.dump.enc`), dechiffrer avant restauration :
   ```bash
   openssl enc -d -aes-256-cbc -pbkdf2 -in tocmanager.dump.enc -out tocmanager.dump -pass env:BACKUP_ENCRYPTION_PASSPHRASE
   ```
3. Restaurer sur la base cible (apres creation d'une base vierge ou snapshot de securite) :
   ```bash
   pg_restore --clean --if-exists --no-owner --no-privileges --dbname="$TARGET_DATABASE_URL" tocmanager.dump
   ```
4. Verifier l'integrite :
   - Lancer `alembic upgrade head` pour s'assurer de l'alignement des migrations.
   - Verifier `GET /health/ready` (`database: ok`).
