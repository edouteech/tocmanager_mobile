from fastapi import Depends, HTTPException, status
from app.api import deps
from app.models import User


def require_superadmin(user: User = Depends(deps.get_current_user)) -> User:
    """Strict access control reserved exclusively for platform superadmins."""
    if user.role != "superadmin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès réservé aux super-administrateurs de la plateforme.",
        )
    return user
