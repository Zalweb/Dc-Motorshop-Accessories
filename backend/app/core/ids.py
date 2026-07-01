"""UUID v7 generation (time-ordered, client-generatable).

Python 3.12's stdlib has no `uuid7`, so we build one per RFC 9562: 48-bit Unix-ms
timestamp, 4-bit version, 12 random bits, 2-bit variant, 62 random bits. Time-ordering
keeps Postgres B-tree indexes append-friendly while staying collision-safe offline.
"""

import secrets
import time
from uuid import UUID


def uuid7() -> UUID:
    unix_ts_ms = int(time.time() * 1000) & ((1 << 48) - 1)
    value = unix_ts_ms << 80
    value |= 0x7 << 76  # version 7
    value |= secrets.randbits(12) << 64  # rand_a
    value |= 0b10 << 62  # RFC 4122 variant
    value |= secrets.randbits(62)  # rand_b
    return UUID(int=value)
