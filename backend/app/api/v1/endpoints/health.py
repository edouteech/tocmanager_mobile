from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.services.storage_service import check_storage_ready

router = APIRouter()


@router.get("/health")
def health_check():
    return {"status": "ok", "app": settings.PROJECT_NAME, "version": settings.VERSION}


@router.get("/health/live")
def health_live():
    return {"status": "alive", "app": settings.PROJECT_NAME, "version": settings.VERSION}


@router.get("/health/ready")
def health_ready(db: Session = Depends(get_db)):
    db_status = "ok"
    storage_status = "ok"
    healthy = True

    try:
        db.execute(text("SELECT 1"))
    except Exception:
        db_status = "error"
        healthy = False

    try:
        storage_status = check_storage_ready()
    except Exception:
        storage_status = "error"
        healthy = False

    payload = {
        "status": "ready" if healthy else "not_ready",
        "database": db_status,
        "storage": storage_status,
    }
    if not healthy:
        return JSONResponse(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, content=payload)
    return payload
