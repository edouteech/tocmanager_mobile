"""Drop legacy Boutique.schema_name column and unused sync_events table.

Revision ID: 0002_drop_legacy_schema_name_and_sync_event
Revises: 0001_initial_schema_and_rls
Create Date: 2026-11-24
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0002_drop_legacy_schema_name_and_sync_event"
down_revision: Union[str, None] = "0001_initial_schema_and_rls"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if "boutiques" in inspector.get_table_names():
        cols = {c["name"] for c in inspector.get_columns("boutiques")}
        if "schema_name" in cols:
            with op.batch_alter_table("boutiques") as batch_op:
                batch_op.drop_column("schema_name")

    if "sync_events" in inspector.get_table_names():
        op.drop_table("sync_events")


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if "boutiques" in inspector.get_table_names():
        cols = {c["name"] for c in inspector.get_columns("boutiques")}
        if "schema_name" not in cols:
            with op.batch_alter_table("boutiques") as batch_op:
                batch_op.add_column(sa.Column("schema_name", sa.String(length=63), nullable=True))
