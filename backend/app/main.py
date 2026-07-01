"""FastAPI application factory.

Wires middleware (request-id, security headers, HTTPS redirect in prod, locked CORS),
the error envelope, and the versioned router. The app boots without a database so the
health check and container start-ordering are robust.
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.httpsredirect import HTTPSRedirectMiddleware

from app.api.v1.router import api_router
from app.core.config import Settings, get_settings
from app.core.database import dispose_engine
from app.core.errors import register_exception_handlers
from app.core.logging import configure_logging
from app.core.middleware import RequestIdMiddleware, SecurityHeadersMiddleware


@asynccontextmanager
async def lifespan(_: FastAPI):
    configure_logging()
    yield
    await dispose_engine()


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or get_settings()
    configure_logging(logging.INFO)

    app = FastAPI(
        title="DC Motorshop & Accessories API",
        version="0.1.0",
        lifespan=lifespan,
        docs_url="/docs" if not settings.is_prod else None,
        redoc_url=None,
        openapi_url="/openapi.json" if not settings.is_prod else None,
    )

    # Order matters: request-id is outermost so every later layer/log sees it.
    app.add_middleware(RequestIdMiddleware)
    app.add_middleware(SecurityHeadersMiddleware)

    if settings.is_prod:
        app.add_middleware(HTTPSRedirectMiddleware)

    # CORS: deny by default. Mobile clients send no Origin; only explicit web origins pass.
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_allow_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
    )

    register_exception_handlers(app)
    app.include_router(api_router, prefix=settings.api_base_path)
    return app


app = create_app()
