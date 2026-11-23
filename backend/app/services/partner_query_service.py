from typing import Any, Optional, Sequence, Type
from sqlalchemy import case, func, or_
from sqlalchemy.orm import Session

from app.services.pagination_service import paginate_sqlalchemy


def list_partners_response(
    db: Session,
    model: Type[Any],
    boutique_id: str,
    search_columns: Sequence[Any],
    schema_cls: Type[Any],
    total_key: str,
    debtors_key: str,
    q: Optional[str],
    only_with_balance: bool,
    sort: Optional[str],
    paginated: bool,
    page: int,
    limit: int,
    offset: int,
) -> Any:
    """List clients or suppliers with optional SQL pagination and balance KPI summary."""
    base_query = db.query(model).filter(
        model.boutique_id == boutique_id,
        model.deleted_at.is_(None),
    )
    query = base_query
    if q and q.strip():
        search = f"%{q.strip()}%"
        query = query.filter(or_(*[col.ilike(search) for col in search_columns]))
    if only_with_balance:
        query = query.filter(model.balance > 0)

    if sort == "balance_desc":
        ordered = query.order_by(model.balance.desc(), model.name.asc())
    elif sort == "balance_asc":
        ordered = query.order_by(model.balance.asc(), model.name.asc())
    else:
        ordered = query.order_by(model.name.asc())

    if not paginated:
        return [
            schema_cls.model_validate(item).model_dump()
            for item in ordered.offset(offset).limit(limit).all()
        ]

    total_c, debtors_c, settled_c, total_debt = base_query.with_entities(
        func.count(model.sync_id),
        func.coalesce(func.sum(case((model.balance > 0, 1), else_=0)), 0),
        func.coalesce(func.sum(case((model.balance <= 0, 1), else_=0)), 0),
        func.coalesce(func.sum(case((model.balance > 0, model.balance), else_=0.0)), 0.0),
    ).one()
    summary = {
        total_key: int(total_c or 0),
        debtors_key: int(debtors_c or 0),
        "settled_count": int(settled_c or 0),
        "total_debt": float(total_debt or 0.0),
    }
    return paginate_sqlalchemy(
        ordered,
        page=page,
        limit=limit,
        summary=summary,
        serializer=lambda item: schema_cls.model_validate(item).model_dump(),
    )
