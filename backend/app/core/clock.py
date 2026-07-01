"""Single source of 'now' so tests can reason about time and everything stays UTC-aware."""

from datetime import UTC, datetime


def utcnow() -> datetime:
    return datetime.now(UTC)
