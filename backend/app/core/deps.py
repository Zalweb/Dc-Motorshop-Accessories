"""Auth + tenant-scoping dependencies.

`get_current_user` decodes the access token and loads the user. The business id is taken
from the JWT (`bid`) and asserted against the row — it is NEVER read from request input.
"""

from uuid import UUID

from fastapi import Depends, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.core.errors import AppError
from app.core.security import TokenError, decode_token
from app.models.business import Business
from app.models.user import User

_bearer = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    session: AsyncSession = Depends(get_session),
) -> User:
    if credentials is None:
        raise TokenError(code="unauthorized", message="Authentication required")
    claims = decode_token(credentials.credentials, expected_type="access")
    user_id = UUID(claims["sub"])
    business_id = UUID(claims["bid"])
    user = await session.get(User, user_id)
    if user is None or user.deleted_at is not None or user.business_id != business_id:
        raise TokenError(code="unauthorized", message="Authentication required")
    return user


async def get_current_business_id(user: User = Depends(get_current_user)) -> UUID:
    """The tenant scope for every owned query — sourced only from the authenticated user."""
    return user.business_id


async def get_current_business(
    business_id: UUID = Depends(get_current_business_id),
    session: AsyncSession = Depends(get_session),
) -> Business:
    business = await session.get(Business, business_id)
    if business is None:
        raise TokenError(code="unauthorized", message="Authentication required")
    return business


def require_role(*allowed: str):
    async def _checker(user: User = Depends(get_current_user)) -> User:
        if user.role not in allowed:
            raise AppError(
                code="forbidden",
                message="Insufficient permissions",
                status_code=status.HTTP_403_FORBIDDEN,
            )
        return user

    return _checker
