import math
from typing import Any, Callable, Dict, List, Optional


def compute_offset(page: int, limit: int) -> int:
    """Compute zero-based SQL offset from 1-based page number and limit."""
    return max(0, (max(1, page) - 1) * max(1, limit))


def build_paginated_response(
    items: List[Any],
    total: int,
    page: int,
    limit: int,
    summary: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Build standard paginated response dictionary with optional SQL summary."""
    safe_page = max(1, page)
    safe_limit = max(1, limit)
    pages = max(1, math.ceil(total / safe_limit)) if total > 0 else 1
    payload: Dict[str, Any] = {
        "items": items,
        "total": int(total),
        "page": safe_page,
        "pages": pages,
        "limit": safe_limit,
    }
    if summary is not None:
        payload["summary"] = summary
    return payload


def paginate_sqlalchemy(
    query: Any,
    page: int,
    limit: int,
    summary: Optional[Dict[str, Any]] = None,
    serializer: Optional[Callable[[Any], Any]] = None,
) -> Dict[str, Any]:
    """Run count and slice on a SQLAlchemy query and wrap in standard envelope."""
    total = int(query.count())
    offset = compute_offset(page, limit)
    rows = query.offset(offset).limit(limit).all()
    items = [serializer(row) for row in rows] if serializer else rows
    return build_paginated_response(
        items=items,
        total=total,
        page=page,
        limit=limit,
        summary=summary,
    )
