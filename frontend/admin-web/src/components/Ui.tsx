import type { ReactNode } from 'react';

export type Tone = 'ok' | 'warn' | 'bad' | 'muted';

export function StatCard({
  label,
  value,
  hint,
  tone = 'ok',
}: {
  label: string;
  value: ReactNode;
  hint?: string;
  tone?: Tone;
}) {
  return (
    <div className={`card stat tone-${tone}`}>
      <div className="value">{value}</div>
      <div className="label">{label}</div>
      {hint && <div className="hint">{hint}</div>}
    </div>
  );
}

export function Badge({ children, tone = 'muted' }: { children: ReactNode; tone?: Tone }) {
  return <span className={`badge tone-${tone}`}>{children}</span>;
}

export function SectionHead({ title, right }: { title: string; right?: ReactNode }) {
  return (
    <div className="section-head">
      <p className="section-label">{title}</p>
      {right && <span className="muted">{right}</span>}
    </div>
  );
}

export function EmptyState({ text }: { text: string }) {
  return <div className="card empty">{text}</div>;
}

/**
 * Yukleme durumu: veri ZATEN varsa gosterilmez. Canli yenilenen bir panelde her
 * turda "Yukleniyor" gostermek ekrani okunamaz hale getirir.
 */
export function Loader({ show }: { show: boolean }) {
  return show ? <p className="muted">Yükleniyor…</p> : null;
}

export function ErrorLine({ text }: { text: string | null }) {
  return text ? <p className="error">{text}</p> : null;
}

export function Pagination({
  page,
  totalPages,
  totalElements,
  onChange,
}: {
  page: number;
  totalPages: number;
  totalElements: number;
  onChange: (page: number) => void;
}) {
  if (totalPages <= 1) {
    return <p className="muted pager-info">{totalElements} kayıt</p>;
  }

  return (
    <div className="pager">
      <button className="ghost" disabled={page <= 0} onClick={() => onChange(page - 1)}>
        Önceki
      </button>
      <span className="muted">
        {page + 1} / {totalPages} · {totalElements} kayıt
      </span>
      <button className="ghost" disabled={page + 1 >= totalPages} onClick={() => onChange(page + 1)}>
        Sonraki
      </button>
    </div>
  );
}

/** Tarihleri her sayfada ayri ayri bicimlendirmemek icin. */
export function formatDateTime(value: string | null | undefined): string {
  if (!value) return '—';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? '—' : date.toLocaleString('tr-TR');
}

export function formatMoney(value: number | null | undefined): string {
  if (value === null || value === undefined) return '—';
  return `₺${Number(value).toLocaleString('tr-TR', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}`;
}

/**
 * `<input type="datetime-local">` değerini (yerel saat) ISO anına çevirir. Boş değer
 * süzgeç yok demektir.
 */
export function localDateTimeToIso(value: string): string | undefined {
  if (!value) return undefined;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? undefined : date.toISOString();
}

/**
 * `<input type="date">` değerinin YEREL gün başını ISO anı olarak döner.
 * `new Date('2026-09-01')` UTC gece yarısı sayılır (Türkiye'de 03:00); saat bu yüzden
 * açıkça eklenir. `endExclusive` verilirse ertesi günün başı döner: sunucu üst sınırı
 * hariç tutuyor, bitiş günü aralığa dahil olsun.
 */
export function localDateToIso(value: string, endExclusive = false): string | undefined {
  if (!value) return undefined;
  const date = new Date(`${value}T00:00`);
  if (Number.isNaN(date.getTime())) return undefined;
  if (endExclusive) date.setDate(date.getDate() + 1);
  return date.toISOString();
}
