#!/usr/bin/env python3
"""
Script d'upload automatique d'artéfacts de build vers Google Drive.
Utilise l'API Google Drive v3 avec un compte de service fourni via GDRIVE_CREDENTIALS.
Si un fichier de même nom existe déjà dans le dossier, il est mis à jour
(ce qui conserve le même lien de partage permanent).
"""

import os
import sys
import json
import base64
import mimetypes
import socket

# Configuration sûre de l'encodage pour Windows (évite les crashs cp1252 charmap)
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

# Augmentation du timeout socket pour les gros fichiers (68 Mo+)
socket.setdefaulttimeout(300)

DEFAULT_FOLDER_ID = "12WVpbRWejBpp3ckRn7i_QhlWKBCSpGkB"


def get_credentials():
    """Charge les identifiants du compte de service depuis GDRIVE_CREDENTIALS."""
    raw_env = os.environ.get("GDRIVE_CREDENTIALS", "").strip()
    if not raw_env:
        return None
    try:
        if raw_env.startswith("{"):
            return json.loads(raw_env)
        return json.loads(base64.b64decode(raw_env).decode("utf-8"))
    except Exception as exc:
        print(f"[ERROR] GDRIVE_CREDENTIALS invalide : {exc}", file=sys.stderr)
        return None


def upload_chunks(request, filename):
    """Envoi par morceaux (chunked) avec retries pour éviter les timeouts."""
    response = None
    while response is None:
        status, response = request.next_chunk(num_retries=5)
        if status:
            percent = int(status.progress() * 100)
            print(f"  -> {filename}: {percent}%")
    return response


def main():
    args = sys.argv[1:]
    custom_folder_id = None
    skip_if_missing = False
    files_to_upload = []

    i = 0
    while i < len(args):
        if args[i] in ("--folder-id", "-f", "--folder") and i + 1 < len(args):
            custom_folder_id = args[i + 1].strip()
            i += 2
        elif args[i] == "--skip-if-missing":
            skip_if_missing = True
            i += 1
        else:
            files_to_upload.append(args[i])
            i += 1

    if not files_to_upload:
        print(
            "Usage: upload_to_gdrive.py [--folder-id <id>] [--skip-if-missing] <file1> [<file2> ...]"
        )
        return 0

    creds_info = get_credentials()
    if not creds_info:
        msg = "Variable d'environnement GDRIVE_CREDENTIALS absente ou invalide."
        if skip_if_missing and not os.environ.get("GDRIVE_CREDENTIALS", "").strip():
            print(f"[SKIP] {msg}")
            return 0
        print(f"[ERROR] {msg}", file=sys.stderr)
        return 1

    try:
        from google.oauth2 import service_account
        from googleapiclient.discovery import build
        from googleapiclient.http import MediaFileUpload
    except ImportError:
        print("[ERROR] Modules google-api-python-client / google-auth manquants.", file=sys.stderr)
        return 1

    folder_id = (
        custom_folder_id
        or os.environ.get("GDRIVE_FOLDER_ID", "").strip()
        or DEFAULT_FOLDER_ID
    )

    try:
        creds = service_account.Credentials.from_service_account_info(
            creds_info, scopes=["https://www.googleapis.com/auth/drive"]
        )
        service = build("drive", "v3", credentials=creds)
    except Exception as exc:
        print(f"[ERROR] Impossible d'initialiser le client Google Drive : {exc}", file=sys.stderr)
        return 1

    print(f"[INFO] Destination Google Drive Dossier ID: {folder_id}")

    for file_path in files_to_upload:
        if not os.path.isfile(file_path):
            print(f"[SKIP] Fichier introuvable, ignoré : {file_path}")
            continue

        filename = os.path.basename(file_path)
        filesize_mb = os.path.getsize(file_path) / (1024 * 1024)
        mime_type, _ = mimetypes.guess_type(file_path)
        if not mime_type:
            mime_type = "application/octet-stream"

        print(f"\n[UPLOAD] Traitement de {filename} ({filesize_mb:.1f} Mo)...")

        query = f"'{folder_id}' in parents and name = '{filename}' and trashed = false"
        try:
            results = (
                service.files()
                .list(
                    q=query,
                    fields="files(id, name)",
                    supportsAllDrives=True,
                    includeItemsFromAllDrives=True,
                )
                .execute()
            )
            existing_files = results.get("files", [])
        except Exception as exc:
            print(f"[WARN] Erreur lors de la recherche dans Google Drive : {exc}")
            existing_files = []

        media = MediaFileUpload(
            file_path, mimetype=mime_type, resumable=True, chunksize=1024 * 1024 * 5
        )

        try:
            if existing_files:
                file_id = existing_files[0]["id"]
                print(f"[UPDATE] Mise à jour du fichier existant (ID: {file_id})...")
                request = service.files().update(
                    fileId=file_id,
                    media_body=media,
                    fields="id, name",
                    supportsAllDrives=True,
                )
                updated = upload_chunks(request, filename)
                print(f"[OK] Fichier mis à jour avec succès : {updated.get('name')}")
            else:
                print("[CREATE] Tentative de création du fichier sur Google Drive...")
                metadata = {"name": filename, "parents": [folder_id]}
                try:
                    request = service.files().create(
                        body=metadata,
                        media_body=media,
                        fields="id, name",
                        supportsAllDrives=True,
                    )
                    created = upload_chunks(request, filename)
                    print(
                        f"[OK] Fichier créé avec succès : {created.get('name')} (ID: {created.get('id')})"
                    )
                except Exception as create_err:
                    err_str = str(create_err)
                    if "storageQuotaExceeded" in err_str or "quota" in err_str.lower():
                        print(
                            f"[INFO] Quota compte de service (0 Mo) : '{filename}' ne peut pas être créé de zéro."
                        )
                        print(
                            f"Déposez un fichier nommé '{filename}' dans le dossier Drive cible pour activer sa mise à jour."
                        )
                    else:
                        print(f"[ERROR] Échec de création pour {filename} : {create_err}")
        except Exception as exc:
            print(f"[ERROR] Échec de la mise à jour pour {filename} : {exc}")

    print("\n[DONE] Fin du traitement Google Drive.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
