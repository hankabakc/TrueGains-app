import { describe, expect, it } from 'vitest';
import { qs } from './client';

describe('qs() query string builder', () => {
  it('boş nesne için boş dize döner', () => {
    expect(qs({})).toBe('');
  });

  it('tek değer için doğru sorgu dizesi üretir', () => {
    expect(qs({ a: 1 })).toBe('?a=1');
  });

  it('null, undefined ve boş dize parametrelerini eler', () => {
    expect(qs({ a: 1, b: null, c: undefined, d: '' })).toBe('?a=1');
  });

  it('false değerini korur (pasif hesap filtresi)', () => {
    // if (value) kısayoluna geçilirse bu sessizce düşer ve yönetici pasif hesapları filtreleyemez.
    expect(qs({ active: false })).toBe('?active=false');
  });

  it('0 değerini korur (ilk sayfa filtresi)', () => {
    // Aynı tuzak; ilk sayfa istenirken parametre düşerse sunucu varsayılanına döner.
    expect(qs({ page: 0 })).toBe('?page=0');
  });

  it('özel karakterleri URL encode eder', () => {
    expect(qs({ query: 'a@b.com' })).toBe('?query=a%40b.com');
  });
});
