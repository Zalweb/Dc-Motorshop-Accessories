export function getTodayString(): string {
  const now = new Date();
  return now.toISOString().split('T')[0];
}

export function formatDate(dateString?: string | null): string {
  if (!dateString) return '';
  const date = new Date(dateString);
  if (isNaN(date.getTime())) return dateString;
  return new Intl.DateTimeFormat('en-PH', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(date);
}

export function formatDateTime(dateString?: string | null): string {
  if (!dateString) return '';
  const date = new Date(dateString);
  if (isNaN(date.getTime())) return dateString;
  return new Intl.DateTimeFormat('en-PH', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  }).format(date);
}

export function formatTime(dateString?: string | null): string {
  if (!dateString) return '';
  const date = new Date(dateString);
  if (isNaN(date.getTime())) return dateString;
  return new Intl.DateTimeFormat('en-PH', {
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  }).format(date);
}

export type DateFilterType = 'today' | 'yesterday' | 'this_week' | 'this_month' | 'this_year' | 'all' | 'custom';

export function isDateInFilter(dateString: string, filter: DateFilterType, customStart?: string, customEnd?: string): boolean {
  if (filter === 'all') return true;
  const d = new Date(dateString);
  const now = new Date();

  // Normalize dates to local start of day
  const targetDate = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  const oneDay = 24 * 60 * 60 * 1000;

  switch (filter) {
    case 'today':
      return targetDate === today;
    case 'yesterday':
      return targetDate === today - oneDay;
    case 'this_week': {
      const dayOfWeek = now.getDay();
      const startOfWeek = today - (dayOfWeek * oneDay);
      return targetDate >= startOfWeek && targetDate <= today + oneDay;
    }
    case 'this_month':
      return d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth();
    case 'this_year':
      return d.getFullYear() === now.getFullYear();
    case 'custom': {
      if (!customStart && !customEnd) return true;
      const start = customStart ? new Date(customStart).getTime() : 0;
      const end = customEnd ? new Date(customEnd).getTime() + oneDay : Infinity;
      return targetDate >= start && targetDate <= end;
    }
    default:
      return true;
  }
}
