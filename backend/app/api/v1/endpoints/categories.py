from typing import Any, List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status, Response
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.api import deps
from app.core.database import get_db
from app.models import Category, Product, AuditLog, User
from app.schemas.entities import CategoryCreate, CategoryUpdate, CategoryResponse

router = APIRouter()

@router.get("", response_model=List[CategoryResponse])
def list_categories(
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """Liste toutes les catégories avec le nombre de produits associés."""
    cats = db.query(Category).filter(Category.deleted_at.is_(None)).order_by(Category.name.asc()).all()
    results = []
    for c in cats:
        count = db.query(func.count(Product.sync_id)).filter(
            Product.category_sync_id == c.sync_id,
            Product.deleted_at.is_(None)
        ).scalar() or 0
        results.append(CategoryResponse(
            sync_id=c.sync_id,
            name=c.name,
            description=c.description,
            color=c.color,
            icon=c.icon,
            created_at=c.created_at,
            updated_at=c.updated_at,
            products_count=count,
        ))
    return results

@router.post("", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(
    data: CategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
) -> Any:
    """Crée une nouvelle catégorie d'articles."""
    now = datetime.now(timezone.utc)
    category = Category(
        name=data.name.strip(),
        description=data.description,
        color=data.color or "#4F46E5",
        icon=data.icon or "Package",
        created_at=now,
        updated_at=now,
    )
    db.add(category)
    db.flush()

    db.add(AuditLog(
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        action="CATEGORY_CREATE",
        entity_type="category",
        entity_id=category.sync_id,
        details={"name": category.name},
        created_at=now,
    ))
    db.commit()
    db.refresh(category)

    return CategoryResponse(
        sync_id=category.sync_id,
        name=category.name,
        description=category.description,
        color=category.color,
        icon=category.icon,
        created_at=category.created_at,
        updated_at=category.updated_at,
        products_count=0,
    )

@router.put("/{sync_id}", response_model=CategoryResponse)
def update_category(
    sync_id: str,
    data: CategoryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
) -> Any:
    """Modifie une catégorie existante."""
    cat = db.query(Category).filter(Category.sync_id == sync_id, Category.deleted_at.is_(None)).first()
    if not cat:
        raise HTTPException(status_code=404, detail="Catégorie introuvable")

    update_dict = data.model_dump(exclude_unset=True)
    for field, val in update_dict.items():
        setattr(cat, field, val)

    now = datetime.now(timezone.utc)
    cat.updated_at = now

    db.add(AuditLog(
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        action="CATEGORY_UPDATE",
        entity_type="category",
        entity_id=cat.sync_id,
        details=update_dict,
        created_at=now,
    ))
    db.commit()
    db.refresh(cat)

    count = db.query(func.count(Product.sync_id)).filter(
        Product.category_sync_id == cat.sync_id,
        Product.deleted_at.is_(None)
    ).scalar() or 0

    return CategoryResponse(
        sync_id=cat.sync_id,
        name=cat.name,
        description=cat.description,
        color=cat.color,
        icon=cat.icon,
        created_at=cat.created_at,
        updated_at=cat.updated_at,
        products_count=count,
    )

@router.delete("/{sync_id}", status_code=status.HTTP_204_NO_CONTENT, response_class=Response)
def delete_category(
    sync_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
):
    """Suppression d'une catégorie."""
    cat = db.query(Category).filter(Category.sync_id == sync_id, Category.deleted_at.is_(None)).first()
    if not cat:
        raise HTTPException(status_code=404, detail="Catégorie introuvable")

    now = datetime.now(timezone.utc)
    cat.deleted_at = now
    cat.updated_at = now

    db.add(AuditLog(
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        action="CATEGORY_DELETE",
        entity_type="category",
        entity_id=cat.sync_id,
        details={"name": cat.name},
        created_at=now,
    ))
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
