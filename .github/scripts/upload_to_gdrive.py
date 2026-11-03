#!/usr/bin/env python3
"""
Script d'upload automatique d'artéfacts de build vers Google Drive.
Utilise l'API Google Drive v3 avec un compte de service.
Si un fichier de même nom existe déjà dans le dossier, il est mis à jour
(ce qui conserve le même lien de partage permanent).
Robuste face aux encodages Windows (cp1252) et aux gros fichiers (chunked resumable upload).
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

FALLBACK_CREDENTIALS_B64 = (
    "ewogICJ0eXBlIjogInNlcnZpY2VfYWNjb3VudCIsCiAgInByb2plY3RfaWQiOiAibHlueC01MTE0"
    "MTEiLAogICJwcml2YXRlX2tleV9pZCI6ICJkZGEzMDdkYmNiODRhZjVhZDcyMmRkZmM0ZTkzOTUy"
    "OTI2ZGIxMGJiIiwKICAicHJpdmF0ZV9rZXkiOiAiLS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0t"
    "XG5NSUlFdlFJQkFEQU5CZ2txaGtpRzl3MEJBUUVGQUFTQ0JLY3dnZ1NqQWdFQUFvSUJBUURYK0JC"
    "bFRqS2FEQWxWXG5yeGZOVnNKZzRDMnBVcGlYTXlVU2dNV245SXR6RkkvVFhXRFNpcnNHcWxNU3Ix"
    "RVVmSHJCYzB3MWI0RmRUNlFUXG5ZV0JaSEE1QW8xektmcyt3RUZVTk9lK0JPWTBJZW53by9ZRnd3"
    "aWFHWDRVcHl3MUxYMjBmMkZNY2lzN2YxbzIrXG5MZmFrUVB4ek1iTVg3QlJ5TGduUmFYcjFINEdL"
    "RS9RcnNDaFl5VDdKL0R0V09NQ0Q0NWhtYWovNEErMDhNSnhSXG56ay9HODZONWxRbzdNaVVyMTdj"
    "SThiM3BweHFNMUZTL2pVc0lOemlWL2x4b0o5RE1FVzhPekVEZkRKRWZaNUNlXG5XWklqaXVWWXF3"
    "SUhzbXZBM1l0S29lTko0REFWT1k3Y2c5UGI1SitNYldiQ3dUUHp5eE4vTHB2RFZmVHBqQkhxXG4r"
    "TXptMmdKZEFnTUJBQUVDZ2dFQUM4VmxmMkFIdWdXMTdJbWlqbnFRRloraVhYdzIvT2E0dW8xeU9I"
    "bEhzSG9LXG5iTWJHSkRPVGhnVjZpYVlza1NWSHU0dUJOOWhnQUtuNmsyUFhVSVFLOHRMMGw4VFpw"
    "UXIrMTcyMHBDSnk0V2RyXG5wUUJNTWMwak5HZTRabEsrNHNETXZkT1lsQkdzdk42QTAwREdGS1hH"
    "SExFMHhiVUVXRVRTSEN2WG04eWZ6dHExXG42K2JaTjlWOUpYVjN0RUVtdCs5ZWtwR1ZpUmg2MWNO"
    "TndyaS8rV01aYlVwTEQwamwwZmR1cVBWZ1Z5bDhya3cyXG4vRVlaQ0NCWldvaVZ2alBRb2xsL2Rv"
    "VG1qc1dMVzdjT2Vzc2t6Sjd2RnBwZUNDRVdML28xaVlzQlpIM0tkSDRXXG53L3VUbHd5Yk1hU2lI"
    "N2phb1VZNG02UTFuK3ZYMDY4Y0kvUkN0eHdhQVFLQmdRRHgzMCtlUHZpTEovWjlLNGtNXG5jVWZ1"
    "V0ZMZEdXbXFiWFc4UkRPR1NlY1J5cWNjRDVLSWNWZElrMzgwL2pIL0hsV1FnSWZ6blBlc0dsamJr"
    "OGxLXG4vcDFLMWE3NTVPM2VucWJWOEpxa1pFY0UyOVh6ekJDL0pKSTJQeHZqMnBOS2xlSWNFWmpB"
    "V0MwejdsQnltL3NhXG51d3doRGRzVllqSVQxRytRbUs0QlBQRlY0UUtCZ1FEa2xXeC8zLy91dzJB"
    "L25ycGlTdTdvSDlxYWxEV2tzSG5WXG5sblIzV0xVMzdTaGpCVFpTMlJZSHpTckY4Vmk4MkRhNEs3"
    "eHV4RTRRSllGY3k2aElBeklUbUVPZFNoZzg0RlExXG5oNEIyZ2UrZGxSaGc1eUEzMjU3dXVGbGFX"
    "TFl1YjRrWW9PVmZsT2NpV3NITzI3MExCYWdxTmUwWGJWeW9wRHpwXG5jNFNETGlhRC9RS0JnQ05Z"
    "VjhFdlFKRE5TVGJuYXNLWHQwUThRZmV2WkFLVXRsVEp2cUhNSU9rM3JRM3J0S1VkXG5zdnlYR1Vx"
    "OExzQXlSWnkxTzZpODhuQ0M5U001U0h3ZUV3eEJoNjFhNSt2VlVWb0lMQUVENm1EcVl5eWFVSVF1"
    "XG5Ldk9rYTBYenhmeHJSTHlIVWNRaDNwRXRMVEppV3VLQUhQaWpsclZjUVNjbXJ4cjVSTXhIaEpq"
    "aEFvR0FFSzZ6XG5GM1lTcUt0THAvaitvMVBTc2RBNVZSVENBWDM3dGxIZnVDSWFQN1dvUCtuT2VD"
    "ZHR5eTMzRkRFMEI3eEQ2aGNQXG5Eb3AzSkFpSXMyd05vUXZTcU1seERkYXRoQ3ZmR1hVRk5DRHhp"
    "dStwc3RETGNpZ3VKa0FBRFc3eUJOdVJCdUlmXG5PMldUcE5jNDA4OEhzZms4dDYvdDJNcmJlMWRa"
    "TnJSK2xGQlc4VVVDZ1lFQXlLNlpqbWdGYTNmNFV6eVNCVWEvXG42cERiVXBYOEFPVUFReU45bFJN"
    "MEtMdTUxSEdyQ0d6aDMrcHZjOGlOK1NWa01aa1BNMlBuWnVMQ0Q2TGxOKytFXG5FUlc0QlN1Y2ZP"
    "K1pzUU1YUXR2SmI1RGRSbVZDV0gzR2NMS2Z1S1UvSHJwSlAweWZ5aGZCYVdZbnFIQ3BVZERsXG5h"
    "NTRSWUl2NjlyOUg4T3lzSnFwa1pzRT1cbi0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS1cbiIsCiAg"
    "ImNsaWVudF9lbWFpbCI6ICJnaXRodWItYWN0aW9ucy11cGxvYWRlckBseW54LTUxMTQxMS5pYW0u"
    "Z3NlcnZpY2VhY2NvdW50LmNvbSIsCiAgImNsaWVudF9pZCI6ICIxMDM4MDc5MTE5Njc1OTAzMTk1"
    "NTEiLAogICJhdXRoX3VyaSI6ICJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20vby9vYXV0aDIv"
    "YXV0aCIsCiAgInRva2VuX3VyaSI6ICJodHRwczovL29hdXRoMi5nb29nbGVhcGlzLmNvbS90b2tl"
    "biIsCiAgImF1dGhfcHJvdmlkZXJfeDUwOV9jZXJ0X3VybCI6ICJodHRwczovL3d3dy5nb29nbGVh"
    "cGlzLmNvbS9vYXV0aDIvdjEvY2VydHMiLAogICJjbGllbnRfeDUwOV9jZXJ0X3VybCI6ICJodHRw"
    "czovL3d3dy5nb29nbGVhcGlzLmNvbS9yb2JvdC92MS9tZXRhZGF0YS94NTA5L2dpdGh1Yi1hY3Rp"
    "b25zLXVwbG9hZGVyJTQwbHlueC01MTE0MTEuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb20iLAogICJ1"
    "bml2ZXJzZV9kb21haW4iOiAiZ29vZ2xlYXBpcy5jb20iCn0="
)

DEFAULT_FOLDER_ID = "12WVpbRWejBpp3ckRn7i_QhlWKBCSpGkB"


def get_credentials():
    # 1. Priorité aux secrets GitHub si configurés
    raw_env = os.environ.get("GDRIVE_CREDENTIALS", "").strip()
    if raw_env:
        try:
            if raw_env.startswith("{"):
                return json.loads(raw_env)
            else:
                return json.loads(base64.b64decode(raw_env).decode("utf-8"))
        except Exception as e:
            print(f"[WARN] Erreur de parsing GDRIVE_CREDENTIALS: {e}")

    # 2. Repli vers le compte de service permanent
    return json.loads(base64.b64decode(FALLBACK_CREDENTIALS_B64).decode("utf-8"))


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
    files_to_upload = []

    i = 0
    while i < len(args):
        if args[i] in ("--folder-id", "-f", "--folder") and i + 1 < len(args):
            custom_folder_id = args[i + 1].strip()
            i += 2
        else:
            files_to_upload.append(args[i])
            i += 1

    if not files_to_upload:
        print("Usage: upload_to_gdrive.py [--folder-id <id>] <file1> [<file2> ...]")
        return 0

    try:
        from google.oauth2 import service_account
        from googleapiclient.discovery import build
        from googleapiclient.http import MediaFileUpload
    except ImportError:
        print("[WARN] Modules google-api-python-client manquants.")
        return 0

    folder_id = custom_folder_id or os.environ.get("GDRIVE_FOLDER_ID", "").strip() or DEFAULT_FOLDER_ID
    creds_info = get_credentials()

    try:
        creds = service_account.Credentials.from_service_account_info(
            creds_info, scopes=["https://www.googleapis.com/auth/drive"]
        )
        service = build("drive", "v3", credentials=creds)
    except Exception as e:
        print(f"[ERROR] Impossible d'initialiser le client Google Drive: {e}")
        return 0

    print(f"[INFO] Destination Google Drive Dossier ID: {folder_id}")

    for file_path in files_to_upload:
        if not os.path.isfile(file_path):
            print(f"[SKIP] Fichier introuvable, ignore : {file_path}")
            continue

        filename = os.path.basename(file_path)
        filesize_mb = os.path.getsize(file_path) / (1024 * 1024)
        mime_type, _ = mimetypes.guess_type(file_path)
        if not mime_type:
            mime_type = "application/octet-stream"

        print(f"\n[UPLOAD] Traitement de {filename} ({filesize_mb:.1f} Mo)...")

        # Recherche si un fichier porte déjà ce nom dans le dossier cible
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
        except Exception as e:
            print(f"[WARN] Erreur lors de la recherche dans Google Drive : {e}")
            existing_files = []

        # Chunks de 5 Mo pour garantir la stabilité même en cas de mauvaise connexion
        media = MediaFileUpload(
            file_path, mimetype=mime_type, resumable=True, chunksize=1024 * 1024 * 5
        )

        try:
            if existing_files:
                file_id = existing_files[0]["id"]
                print(f"[UPDATE] Mise a jour du fichier existant (ID: {file_id})...")
                request = service.files().update(
                    fileId=file_id,
                    media_body=media,
                    fields="id, name",
                    supportsAllDrives=True,
                )
                updated = upload_chunks(request, filename)
                print(f"[OK] Fichier mis a jour avec succes : {updated.get('name')}")
            else:
                print("[CREATE] Tentative de creation du fichier sur Google Drive...")
                metadata = {"name": filename, "parents": [folder_id]}
                try:
                    request = service.files().create(
                        body=metadata,
                        media_body=media,
                        fields="id, name",
                        supportsAllDrives=True,
                    )
                    created = upload_chunks(request, filename)
                    print(f"[OK] Fichier cree avec succes : {created.get('name')} (ID: {created.get('id')})")
                except Exception as create_err:
                    err_str = str(create_err)
                    if "storageQuotaExceeded" in err_str or "quota" in err_str.lower():
                        print(f"[INFO] Quota compte de service (0 Mo) : '{filename}' ne peut pas etre cree de zero.")
                        print(f"👉 Deposez simplement un fichier nomme '{filename}' dans le dossier Drive Lynx pour qu'il soit mis a jour.")
                    else:
                        print(f"[ERROR] Echec de creation pour {filename} : {create_err}")
        except Exception as e:
            print(f"[ERROR] Echec de la mise a jour pour {filename} : {e}")

    print("\n[DONE] Fin du traitement Google Drive.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
