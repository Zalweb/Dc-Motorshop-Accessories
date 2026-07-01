from fastapi import APIRouter, Depends, Request, Response, status
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.core.deps import get_current_user
from app.core.redis import get_redis
from app.models.user import User
from app.schemas.auth import (
    AuthResponse,
    LoginIn,
    MeUpdateIn,
    RefreshIn,
    RegisterIn,
    TokenOut,
    UserOut,
)
from app.services.auth_service import AuthService, TokenPair

router = APIRouter(prefix="/auth", tags=["auth"])


def _service(
    session: AsyncSession = Depends(get_session),
    redis: Redis = Depends(get_redis),
) -> AuthService:
    return AuthService(session, redis)


def _tokens_out(pair: TokenPair) -> TokenOut:
    return TokenOut(
        access_token=pair.access_token,
        refresh_token=pair.refresh_token,
        expires_in=pair.expires_in,
    )


def _client_ip(request: Request) -> str | None:
    return request.client.host if request.client else None


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(
    data: RegisterIn, request: Request, service: AuthService = Depends(_service)
) -> AuthResponse:
    user, tokens = await service.register(
        business_name=data.business_name,
        username=data.username,
        email=data.email,
        password=data.password,
        full_name=data.full_name,
        phone=data.phone,
        ip=_client_ip(request),
    )
    return AuthResponse(user=UserOut.model_validate(user), tokens=_tokens_out(tokens))


@router.post("/login", response_model=AuthResponse)
async def login(
    data: LoginIn, request: Request, service: AuthService = Depends(_service)
) -> AuthResponse:
    user, tokens = await service.login(
        username=data.username, password=data.password, ip=_client_ip(request)
    )
    return AuthResponse(user=UserOut.model_validate(user), tokens=_tokens_out(tokens))


@router.post("/refresh", response_model=TokenOut)
async def refresh(
    data: RefreshIn, request: Request, service: AuthService = Depends(_service)
) -> TokenOut:
    tokens = await service.refresh(refresh_token=data.refresh_token, ip=_client_ip(request))
    return _tokens_out(tokens)


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    data: RefreshIn, request: Request, service: AuthService = Depends(_service)
) -> Response:
    await service.logout(refresh_token=data.refresh_token, ip=_client_ip(request))
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/me", response_model=UserOut)
async def me(user: User = Depends(get_current_user)) -> UserOut:
    return UserOut.model_validate(user)


@router.patch("/me", response_model=UserOut)
async def update_me(
    data: MeUpdateIn,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> UserOut:
    payload = data.model_dump(exclude_unset=True)
    for field, value in payload.items():
        setattr(user, field, value)
    if payload:
        from app.core.clock import utcnow

        user.updated_at = utcnow()
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return UserOut.model_validate(user)
