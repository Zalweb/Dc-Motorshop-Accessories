/**
 * Formats a numeric value into Philippine Peso (₱) string with comma grouping and 2 decimal places.
 * Example: 1250 -> ₱1,250.00
 */
export function formatMoney(amount: number | null | undefined, includeSymbol: boolean = true): string {
  if (amount == null || isNaN(amount)) {
    return includeSymbol ? '₱0.00' : '0.00';
  }
  const formatted = new Intl.NumberFormat('en-PH', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);

  return includeSymbol ? `₱${formatted}` : formatted;
}

/**
 * Parses a string or input value into a clean float amount.
 */
export function parseMoney(input: string | number | null | undefined): number {
  if (input == null) return 0;
  if (typeof input === 'number') return isNaN(input) ? 0 : input;
  const cleaned = input.toString().replace(/[^0-9.-]/g, '');
  const parsed = parseFloat(cleaned);
  return isNaN(parsed) ? 0 : parsed;
}

/**
 * Formats a percentage value (e.g. 24.5%).
 */
export function formatPercent(value: number | null | undefined): string {
  if (value == null || isNaN(value)) return '0.0%';
  return `${value.toFixed(1)}%`;
}
