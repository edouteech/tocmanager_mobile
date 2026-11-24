"""Add user email verification, TOTP 2FA fields, and auth_action_tokens table.

Revision ID: 0003_auth_tokens_and_2fa
Revises: 0002_drop_legacy_fields
Create Date: 2026-11-24
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0003_auth_tokens_and_2fa"
down_revision: Union[str, None] = "0002_drop_legacy_fields"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    tables = set(inspector.get_table_names())

    if "users" in tables:
        cols = {c["name"] for c in inspector.get_columns("users")}
        with op.batch_alter_table("users") as batch_op:
            if "email_verified_at" not in cols:
                batch_op.add_column(sa.Column("email_verified_at", sa.DateTime(timezone=True), nullable=True))
            if "totp_secret" not in cols:
                batch_op.add_column(sa.Column("totp_secret", sa.String(length=64), nullable=True))
            if "totp_enabled" not in cols:
                batch_op.add_column(
                    sa.Column("totp_enabled", sa.Boolean(), nullable=False, server_default=sa.false())
                )

    if "auth_action_tokens" not in tables:
        op.create_table(
            "auth_action_tokens",
            sa.Column("id", sa.String(length=36), primary_key=True),
            sa.Column("user_id", sa.String(length=36), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
            sa.Column("purpose", sa.String(length=32), nullable=False),
            sa.Column("token_hash", sa.String(length=64), nullable=False, unique=True),
            sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=True),
        )
        op.create_index("ix_auth_action_tokens_user_id", "auth_action_tokens", ["user_id"])
        op.create_index("ix_auth_action_tokens_purpose", "auth_action_tokens", ["purpose"])


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    tables = set(inspector.get_table_names())

    if "auth_action_tokens" in tables:
        op.drop_table("auth_action_tokens")

    if "users" in tables:
        cols = {c["name"] for c in inspector.get_columns("users")}
        with op.batch_alter_table("users") as batch_op:
            for col in ("totp_enabled", "totp_secret", "email_verified_at"):
                if col in cols:
                    batch_op.drop_column(col)
