"""Add index on vente_items.vente_sync_id to eliminate sequential scans.

Revision ID: 0004_idx_vente_items_sync_id
Revises: 0003_auth_tokens_and_2fa
Create Date: 2026-11-25
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0004_idx_vente_items_sync_id"
down_revision: Union[str, None] = "0003_auth_tokens_and_2fa"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

INDEX_NAME = "ix_vente_items_vente_sync_id"


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if "vente_items" not in inspector.get_table_names():
        return
    indexes = inspector.get_indexes("vente_items")
    has_name = any(idx.get("name") == INDEX_NAME for idx in indexes)
    has_col = any(idx.get("column_names") == ["vente_sync_id"] for idx in indexes)
    if not has_name and not has_col:
        op.create_index(INDEX_NAME, "vente_items", ["vente_sync_id"])


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if "vente_items" not in inspector.get_table_names():
        return
    indexes = inspector.get_indexes("vente_items")
    if any(idx.get("name") == INDEX_NAME for idx in indexes):
        op.drop_index(INDEX_NAME, table_name="vente_items")
