from typing import Any, Dict
from datetime import datetime, timezone
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api import deps
from app.core.database import get_db
from app.models import StoreSetting, AuditLog
from app.schemas.entities import StoreSettings
from app.services.tenant_context_service import TenantContext

router = APIRouter()

DEFAULT_SETTINGS = {
    "store_name": "TocManager Store",
    "currency": "FCFA",
    "phone": "+228 90 00 00 00",
    "email": "contact@tocmanager.com",
    "address": "Lomé, Togo",
    "tax_rate": "0.0",
    "low_stock_threshold": "5.0",
    "rccm": "",
    "nif": "",
}


def _boutique_defaults(ctx: TenantContext) -> Dict[str, str]:
    base = dict(DEFAULT_SETTINGS)
    base["store_name"] = ctx.boutique.name or DEFAULT_SETTINGS["store_name"]
    base["currency"] = ctx.boutique.currency or DEFAULT_SETTINGS["currency"]
    if ctx.boutique.phone:
        base["phone"] = ctx.boutique.phone
    if ctx.boutique.email:
        base["email"] = ctx.boutique.email
    if ctx.boutique.address:
        base["address"] = ctx.boutique.address
    return base


@router.get("", response_model=StoreSettings)
def get_store_settings(
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
) -> Any:
    """Récupère les paramètres de la boutique active."""
    rows = db.query(StoreSetting).filter(StoreSetting.boutique_id == ctx.boutique.id).all()
    settings_dict = _boutique_defaults(ctx)
    for r in rows:
        settings_dict[r.key] = r.value

    return StoreSettings(
        store_name=settings_dict.get("store_name", DEFAULT_SETTINGS["store_name"]),
        currency=settings_dict.get("currency", DEFAULT_SETTINGS["currency"]),
        phone=settings_dict.get("phone"),
        email=settings_dict.get("email"),
        address=settings_dict.get("address"),
        tax_rate=float(settings_dict.get("tax_rate", "0.0") or 0.0),
        low_stock_threshold=float(settings_dict.get("low_stock_threshold", "5.0") or 5.0),
        rccm=settings_dict.get("rccm"),
        nif=settings_dict.get("nif"),
    )


@router.put("", response_model=StoreSettings)
def update_store_settings(
    settings_in: StoreSettings,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin"])),
    db: Session = Depends(get_db),
) -> Any:
    """Met à jour les paramètres propres à la boutique active."""
    current_user = ctx.user
    now = datetime.now(timezone.utc)
    in_dict = {
        "store_name": settings_in.store_name,
        "currency": settings_in.currency,
        "phone": settings_in.phone or "",
        "email": settings_in.email or "",
        "address": settings_in.address or "",
        "tax_rate": str(settings_in.tax_rate),
        "low_stock_threshold": str(settings_in.low_stock_threshold),
        "rccm": settings_in.rccm or "",
        "nif": settings_in.nif or "",
    }

    for k, v in in_dict.items():
        existing = (
            db.query(StoreSetting)
            .filter(StoreSetting.boutique_id == ctx.boutique.id, StoreSetting.key == k)
            .first()
        )
        if existing:
            existing.value = v
            existing.updated_at = now
        else:
            db.add(StoreSetting(boutique_id=ctx.boutique.id, key=k, value=v, updated_at=now))

    db.add(AuditLog(
        boutique_id=ctx.boutique.id,
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        action="SETTINGS_UPDATE",
        entity_type="settings",
        entity_id=ctx.boutique.id,
        details=in_dict,
        created_at=now,
    ))
    db.commit()
    return settings_in
