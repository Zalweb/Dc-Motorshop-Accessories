"""Aggregates all v1 routers under the `/v1` base path."""

from fastapi import APIRouter, Depends

from app.api.v1 import (
    auth,
    backup,
    business,
    categories,
    dashboard,
    expenses,
    health,
    products,
    sales,
    sync,
)
from app.core.rate_limit import global_rate_limit

api_router = APIRouter()

# Health is unauthenticated and unthrottled (load balancers poll it).
api_router.include_router(health.router)

# Everything else shares the per-IP global rate limit.
_limited = APIRouter(dependencies=[Depends(global_rate_limit)])
_limited.include_router(auth.router)
_limited.include_router(business.router)
_limited.include_router(categories.router)
_limited.include_router(products.router)
_limited.include_router(sales.router)
_limited.include_router(expenses.router)
_limited.include_router(dashboard.router)
_limited.include_router(backup.router)
_limited.include_router(sync.router)
api_router.include_router(_limited)
