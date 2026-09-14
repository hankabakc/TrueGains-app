import { describe, expect, it } from 'vitest';
import { formatDateTime, formatMoney, localDateToIso, localDateTimeToIso } from './Ui';

describe('Ui formatters', () => {
  it('formatDateTime boş veya tanımsız değerlerde tire döner', () => {
    expect(formatDateTime(null)).toBe('—');
    expect(formatDateTime(undefined)).toBe('—');
    expect(formatDateTime('')).toBe('—');
  });

  it('formatDateTime geçersiz tarih dizesinde tire döner', () => {
    expect(formatDateTime('abc')).toBe('—');
  });

  it('formatMoney null/undefined için tire, 0 için ₺0 döner', () => {
    expect(formatMoney(null)).toBe('—');
    expect(formatMoney(undefined)).toBe('—');
    // Sıfır tutar gerçek bir değerdir; '—' dönerse "veri yok" ile "ödeme yok" birbirine karışır.
    expect(formatMoney(0)).toBe('₺0');
  });
});

describe('tarih süzgeci yardımcıları', () => {
  it('localDateTimeToIso yerel saati ISO anına çevirir, boş değerde undefined döner', () => {
    expect(localDateTimeToIso('2026-09-06T18:00')).toBe(new Date(2026, 8, 6, 18, 0).toISOString());
    expect(localDateTimeToIso('')).toBeUndefined();
    expect(localDateTimeToIso('gecersiz')).toBeUndefined();
  });

  it('localDateToIso yerel gün başını, endExclusive ile ertesi günün başını verir', () => {
    expect(localDateToIso('2026-09-01')).toBe(new Date(2026, 8, 1).toISOString());
    expect(localDateToIso('2026-09-03', true)).toBe(new Date(2026, 8, 4).toISOString());
    expect(localDateToIso('2026-09-30', true)).toBe(new Date(2026, 9, 1).toISOString());
    expect(localDateToIso('')).toBeUndefined();
    expect(localDateToIso('gecersiz')).toBeUndefined();
  });
});
