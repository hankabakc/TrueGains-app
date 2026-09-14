import { useState } from 'react';
import { financeApi } from '../api/admin';
import { SEARCH_DEBOUNCE_MS, useDebouncedValue } from '../hooks/useDebouncedValue';
import { useResource } from '../hooks/useResource';
import {
  Badge,
  EmptyState,
  ErrorLine,
  Loader,
  Pagination,
  SectionHead,
  StatCard,
  formatDateTime,
  formatMoney,
  localDateToIso,
  type Tone,
} from '../components/Ui';

// Durumlar FinanceService'te yazılıyor: PENDING (ödeme başlatıldı), SUCCESS, FAILED.
// Listede olmayan durum ham koduyla görünür.
const PAYMENT_STATUS: Record<string, { label: string; tone: Tone }> = {
  SUCCESS: { label: 'Başarılı', tone: 'ok' },
  PENDING: { label: 'Bekliyor', tone: 'warn' },
  FAILED: { label: 'Başarısız', tone: 'bad' },
};

export default function FinancePage() {
  const [status, setStatus] = useState('');
  const [email, setEmail] = useState('');
  const debouncedEmail = useDebouncedValue(email, SEARCH_DEBOUNCE_MS);
  const [since, setSince] = useState('');
  const [until, setUntil] = useState('');
  const [page, setPage] = useState(0);

  const revenue = useResource(() => financeApi.revenue(), []);
  const payments = useResource(
    () =>
      financeApi.payments({
        status: status || undefined,
        email: debouncedEmail || undefined,
        from: localDateToIso(since),
        to: localDateToIso(until, true),
        page,
        size: 20,
      }),
    [status, debouncedEmail, since, until, page],
  );

  const r = revenue.data;

  return (
    <>
      <SectionHead title="Gelir" />
      <ErrorLine text={revenue.error} />
      <Loader show={revenue.loading && !r} />

      {r && (
        <div className="grid">
          <StatCard label="Bugün" value={formatMoney(r.revenueToday)} hint="son 24 saat" />
          <StatCard label="Son 7 gün" value={formatMoney(r.revenue7d)} />
          <StatCard label="Son 30 gün" value={formatMoney(r.revenue30d)} />
          <StatCard label="Toplam" value={formatMoney(r.revenueTotal)} />
          <StatCard label="Başarılı ödeme" value={r.successfulPayments.toLocaleString('tr-TR')} />
          {/* Basarisiz odeme sayisi, odeme saglayicisindaki sorunun ILK belirtisidir. */}
          <StatCard
            label="Başarısız ödeme"
            value={r.failedPayments.toLocaleString('tr-TR')}
            tone={r.failedPayments > 0 ? 'warn' : 'ok'}
          />
          <StatCard label="Aktif abonelik" value={r.activeSubscriptions.toLocaleString('tr-TR')} />
          <StatCard
            label="7 gün içinde bitiyor"
            value={r.expiringIn7d.toLocaleString('tr-TR')}
            hint="yenilenmezse kayıp"
            tone={r.expiringIn7d > 0 ? 'warn' : 'ok'}
          />
        </div>
      )}

      <SectionHead title="Ödemeler" />

      <div className="filters">
        <select
          value={status}
          onChange={(e) => {
            setStatus(e.target.value);
            setPage(0);
          }}
        >
          <option value="">Tüm durumlar</option>
          <option value="SUCCESS">Başarılı</option>
          <option value="FAILED">Başarısız</option>
        </select>
        <input
          placeholder="Kullanıcı e-postası…"
          value={email}
          onChange={(e) => {
            setEmail(e.target.value);
            setPage(0);
          }}
        />
        <input
          type="date"
          aria-label="Başlangıç tarihi"
          value={since}
          onChange={(e) => {
            setSince(e.target.value);
            setPage(0);
          }}
        />
        <input
          type="date"
          aria-label="Bitiş tarihi"
          value={until}
          onChange={(e) => {
            setUntil(e.target.value);
            setPage(0);
          }}
        />
      </div>

      <ErrorLine text={payments.error} />
      <Loader show={payments.loading && !payments.data} />

      {payments.data && payments.data.content.length === 0 && <EmptyState text="Ödeme kaydı yok." />}

      {payments.data && payments.data.content.length > 0 && (
        <>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Tarih</th>
                  <th>Kullanıcı</th>
                  <th>Paket</th>
                  <th>Tutar</th>
                  <th>Durum</th>
                </tr>
              </thead>
              <tbody>
                {payments.data.content.map((p) => (
                  <tr key={p.id}>
                    <td>{formatDateTime(p.transactionDate)}</td>
                    <td>{p.clientEmail ?? '—'}</td>
                    <td>{p.packageName ?? '—'}</td>
                    <td>{formatMoney(p.amount)}</td>
                    <td>
                      <Badge tone={PAYMENT_STATUS[p.status]?.tone ?? 'muted'}>{PAYMENT_STATUS[p.status]?.label ?? p.status}</Badge>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <Pagination
            page={payments.data.pageNumber}
            totalPages={payments.data.totalPages}
            totalElements={payments.data.totalElements}
            onChange={setPage}
          />
        </>
      )}
    </>
  );
}
