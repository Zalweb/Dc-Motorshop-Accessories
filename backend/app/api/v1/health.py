"""Liveness probe. No auth, no DB dependency — always answerable while the process is up."""

from fastapi import APIRouter

router = APIRouter(tags=["health"])


@router.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
