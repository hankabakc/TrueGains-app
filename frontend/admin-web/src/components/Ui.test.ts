import { describe, expect, it } from 'vitest';
import { formatDateTime, formatMoney } from './Ui';

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
