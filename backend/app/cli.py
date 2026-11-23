import argparse
import sys
from app.core.database import SessionLocal, Base, engine
from app.core.security import get_password_hash
from app.models import User


def create_superadmin(username: str, email: str, password: str, full_name: str) -> int:
    if len(password) < 8:
        print("Error: password must be at least 8 characters long.", file=sys.stderr)
        return 1

    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        norm_username = username.strip()
        norm_email = email.strip().lower()
        existing = (
            db.query(User)
            .filter((User.username == norm_username) | (User.email == norm_email))
            .first()
        )
        if existing:
            print(
                f"Error: user already exists with username '{existing.username}' or email '{existing.email}'.",
                file=sys.stderr,
            )
            return 1

        user = User(
            username=norm_username,
            email=norm_email,
            full_name=full_name.strip() or "Super Administrateur Plateforme",
            hashed_password=get_password_hash(password),
            role="superadmin",
            permissions=["*"],
            is_active=True,
        )
        db.add(user)
        db.commit()
        print(f"Superadmin '{user.username}' created successfully.")
        return 0
    finally:
        db.close()


def main() -> int:
    parser = argparse.ArgumentParser(description="TocManager backend CLI utilities.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    sa_parser = subparsers.add_parser("create-superadmin", help="Create a platform superadmin account.")
    sa_parser.add_argument("--username", required=True)
    sa_parser.add_argument("--email", required=True)
    sa_parser.add_argument("--password", required=True)
    sa_parser.add_argument("--full-name", default="Super Administrateur Plateforme")

    args = parser.parse_args()
    if args.command == "create-superadmin":
        return create_superadmin(args.username, args.email, args.password, args.full_name)
    return 1


if __name__ == "__main__":
    sys.exit(main())
