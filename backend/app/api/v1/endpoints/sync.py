from datetime import datetime
from typing import Any, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api import deps
from app.core.database import get_db
from app.schemas.sync import SyncPullResponse, SyncPushRequest, SyncPushResult
from app.services.sync_pull_service import pull_boutique_changes
from app.services.sync_push_service import push_boutique_changes
from app.services.tenant_context_service import TenantContext

router = APIRouter()


@router.get("/pull", response_model=SyncPullResponse)
def pull_changes(
    since: Optional[datetime] = Query(None, description="Timestamp UTC du dernier pull"),
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
) -> Any:
    """Télécharge les données cloisonnées de la boutique active depuis 'since'."""
    return pull_boutique_changes(db=db, boutique_id=ctx.boutique.id, since=since)


@router.post("/push", response_model=SyncPushResult)
def push_changes(
    payload: SyncPushRequest,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
) -> Any:
    """Reçoit un lot d'entités hors-ligne strictement cloisonné à la boutique active."""
    return push_boutique_changes(db=db, ctx=ctx, payload=payload)
