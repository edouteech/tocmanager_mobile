from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)


def reset_rate_limits() -> None:
    """Réinitialise le stockage en mémoire du rate-limiter (utile pour les tests)."""
    storage = getattr(limiter, "_storage", None)
    if storage is not None and hasattr(storage, "reset"):
        storage.reset()
