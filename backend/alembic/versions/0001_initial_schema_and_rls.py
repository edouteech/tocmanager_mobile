"""Initial TocManager PostgreSQL/SQLite schema and PostgreSQL tenant RLS policies.

Revision ID: 0001_initial_schema_and_rls
Revises:
Create Date: 2026-11-24
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

from app.core.database import Base
from app.core.rls import build_rls_ddl
import app.models  # noqa: F401

revision: str = "0001_initial_schema_and_rls"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    Base.metadata.create_all(bind=bind)
    if bind.dialect.name == "postgresql":
        for stmt in build_rls_ddl():
            op.execute(sa.text(stmt))


def downgrade() -> None:
    bind = op.get_bind()
    Base.metadata.drop_all(bind=bind)
