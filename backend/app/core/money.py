"""Money helpers. All monetary values are Decimal, quantized to 2dp, rounded half-up.

Never use float for money — binary floats can't represent ₱0.10 exactly.
"""

from decimal import ROUND_HALF_UP, Decimal

CENTS = Decimal("0.01")


def q2(value: Decimal) -> Decimal:
    return value.quantize(CENTS, rounding=ROUND_HALF_UP)
