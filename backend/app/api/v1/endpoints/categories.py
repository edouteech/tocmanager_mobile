from typing import Any, List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.core.database import get_db
from app.models import Category, User
from app.schemas.sync import CategorySync
from pydantic import BaseModel

router = APIRouter()

class CategoryCreate(BaseModel):
    name: str
    description: Optional[str] = None
    color: Optional[str] = None
    icon: Optional[str] = None

@router.get("", response_model=List[CategorySync])
def list_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    return db.query(Category).filter(Category.deleted_at.is_(None)).all()

@router.post("", response_model=CategorySync)
def create_category(
    data: CategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
) -> Any:
    now = datetime.now(timezone.utc)
    category = Category(
        name=data.name,
        description=data.description,
        color=data.color,
        icon=data.icon,
        created_at=now,
        updated_at=now,
    )
    db.add(category)
    db.commit()
    db.refresh(category)
    return category
