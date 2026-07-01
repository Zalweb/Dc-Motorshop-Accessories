"""Structured logging that scrubs secrets and tokens before they reach a log sink.

Passwords, JWTs, refresh tokens, and Authorization headers must never be logged
(BACKEND_PLAN §2 "Operations"). The filter redacts known-sensitive substrings.
"""

import logging
import re
import sys

# Patterns whose VALUE must be redacted wherever it appears in a formatted log record.
_REDACTION_PATTERNS = [
    re.compile(r"(?i)(authorization)\s*[:=]\s*\S+"),
    re.compile(r"(?i)(password|passwd|pwd)\s*[\"':=]+\s*\S+"),
    re.compile(r"(?i)(access_token|refresh_token|token|jwt|secret)\s*[\"':=]+\s*\S+"),
    re.compile(r"Bearer\s+[A-Za-z0-9._\-]+"),
    re.compile(r"eyJ[A-Za-z0-9._\-]+"),  # raw JWTs
]


class SecretScrubbingFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        message = record.getMessage()
        scrubbed = message
        for pattern in _REDACTION_PATTERNS:
            scrubbed = pattern.sub(_replace, scrubbed)
        if scrubbed != message:
            record.msg = scrubbed
            record.args = ()
        return True


def _replace(match: re.Match[str]) -> str:
    if match.lastindex:
        return f"{match.group(1)}=[REDACTED]"
    return "[REDACTED]"


def configure_logging(level: int = logging.INFO) -> None:
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(
        logging.Formatter("%(asctime)s %(levelname)s %(name)s [%(request_id)s] %(message)s")
    )
    handler.addFilter(SecretScrubbingFilter())
    handler.addFilter(_RequestIdDefault())

    root = logging.getLogger()
    root.handlers = [handler]
    root.setLevel(level)


class _RequestIdDefault(logging.Filter):
    """Ensure every record has a `request_id` so the formatter never KeyErrors."""

    def filter(self, record: logging.LogRecord) -> bool:
        if not hasattr(record, "request_id"):
            record.request_id = "-"
        return True
