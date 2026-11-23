from typing import Dict, List, Optional

PLATFORM_ROLE_SUPERADMIN = "superadmin"
TENANT_ROLES = ("owner", "store_admin", "manager", "cashier")
ASSIGNABLE_TENANT_ROLES = ("store_admin", "manager", "cashier")

ROLE_PERMISSIONS: Dict[str, List[str]] = {
    "superadmin": ["platform.*"],
    "owner": ["*"],
    "merchant": ["*"],
    "store_admin": ["*"],
    "manager": [
        "sales.*",
        "products.*",
        "categories.*",
        "clients.*",
        "suppliers.*",
        "reports.view",
    ],
    "cashier": [
        "sales.create",
        "sales.view_own",
        "products.view_price",
        "clients.create",
        "clients.view",
    ],
}


def normalize_tenant_role(role: Optional[str]) -> str:
    """Map legacy boutique roles ('admin', 'merchant') to canonical tenant roles."""
    if not role:
        return "cashier"
    if role == "admin":
        return "store_admin"
    if role == "merchant":
        return "owner"
    return role


def get_permissions_for_role(
    role: Optional[str], custom_permissions: Optional[List[str]] = None
) -> List[str]:
    """Return effective permissions list for a platform or boutique role."""
    if role == PLATFORM_ROLE_SUPERADMIN:
        return list(ROLE_PERMISSIONS[PLATFORM_ROLE_SUPERADMIN])
    normalized = normalize_tenant_role(role)
    if normalized in ROLE_PERMISSIONS:
        return list(ROLE_PERMISSIONS[normalized])
    return list(custom_permissions or [])
