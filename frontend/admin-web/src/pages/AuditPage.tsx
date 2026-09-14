import { useState } from 'react';
import { auditApi } from '../api/admin';
import { useResource } from '../hooks/useResource';
import { SEARCH_DEBOUNCE_MS, useDebouncedValue } from '../hooks/useDebouncedValue';
import type { AdminAuditRow } from '../api/types';
import { EmptyState, ErrorLine, Loader, Pagination, SectionHead, formatDateTime, localDateTimeToIso } from '../components/Ui';

// Listede olmayan eylem ham koduyla görünür: yeni eylem eklenince boş hücre çıkmasın.
const ACTION_LABEL: Record<string, string> = {
  ADMIN_ACCESS: 'Panel erişimi',
  ADMIN_USER_STATUS_CHANGE: 'Hesap durumu değişti',
  ADMIN_REPORT_RESOLVE: 'Şikâyet karara bağlandı',
  ACCOUNT_DELETED: 'Hesap silindi',
  DIET_PROGRAM_CREATED: 'Diyet programı oluşturuldu',
  DIET_PROGRAM_ACTIVATED: 'Diyet programı etkinleştirildi',
  DIET_PROGRAM_DELETED: 'Diyet programı silindi',
  DIET_PROGRAM_COPIED: 'Diyet programı kopyalandı',
  DIET_GOALS_UPDATED: 'Diyet hedefleri güncellendi',
  DIET_TEMPLATE_CREATED: 'Diyet şablonu oluşturuldu',
  DIET_TEMPLATE_ASSIGNED: 'Diyet şablonu atandı',
  DIET_TEMPLATE_UNASSIGNED: 'Diyet şablonu ataması kaldırıldı',
};

function actionLabel(action: string): string {
  return ACTION_LABEL[action] ?? action;
}

export default function AuditPage() {
  const [action, setAction] = useState('');
  const [email, setEmail] = useState('');
  const debouncedEmail = useDebouncedValue(email, SEARCH_DEBOUNCE_MS);
  const [since, setSince] = useState('');
  const [until, setUntil] = useState('');
  const [page, setPage] = useState(0);
  const [selected, setSelected] = useState<AdminAuditRow | null>(null);

  const actions = useResource(() => auditApi.actions(), []);
  const logs = useResource(
    () =>
      auditApi.search({
        action: action || undefined,
        email: debouncedEmail || undefined,
        from: localDateTimeToIso(since),
        to: localDateTimeToIso(until),
        page,
        size: 50,
      }),
    [action, debouncedEmail, since, until, page],
  );

  return (
    <>
      <SectionHead title="Denetim defteri" right="salt okunur" />

      <div className="filters">
        <input
          placeholder="E-posta…"
          value={email}
          onChange={(e) => {
            setEmail(e.target.value);
            setPage(0);
          }}
        />
        <select
          value={action}
          onChange={(e) => {
            setAction(e.target.value);
            setPage(0);
          }}
        >
          <option value="">Tüm eylemler</option>
          {(actions.data ?? []).map((a) => (
            <option key={a} value={a}>
              {actionLabel(a)}
            </option>
          ))}
        </select>
        <input
          type="datetime-local"
          aria-label="Başlangıç zamanı"
          value={since}
          onChange={(e) => {
            setSince(e.target.value);
            setPage(0);
          }}
        />
        <input
          type="datetime-local"
          aria-label="Bitiş zamanı"
          value={until}
          onChange={(e) => {
            setUntil(e.target.value);
            setPage(0);
          }}
        />
      </div>

      {/* Defterin silinebilir ya da degistirilebilir olmasi kaydin kendisini
          degersiz kilardi; bu yuzden panelde yalnizca okuma var. */}
      <p className="muted hint-line">
        Bu defter değiştirilemez. Yönetim panelindeki her erişim ve her değişiklik buraya düşer. Bitiş zamanı aralığa dahil değildir.
      </p>

      <ErrorLine text={logs.error} />
      <Loader show={logs.loading && !logs.data} />

      {logs.data && logs.data.content.length === 0 && <EmptyState text="Kayıt bulunamadı." />}

      {logs.data && logs.data.content.length > 0 && (
        <>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Zaman</th>
                  <th>Eylem</th>
                  <th>Kim</th>
                  <th>IP</th>
                  <th>Ayrıntı</th>
                </tr>
              </thead>
              <tbody>
                {logs.data.content.map((row) => (
                  <tr key={row.id} className="clickable" onClick={() => setSelected(row)}>
                    <td>{formatDateTime(row.createdAt)}</td>
                    <td>{actionLabel(row.action)}</td>
                    <td>{row.userEmail ?? '—'}</td>
                    <td className="muted">{row.ipAddress ?? '—'}</td>
                    <td className="muted small">{row.details ?? '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <Pagination
            page={logs.data.pageNumber}
            totalPages={logs.data.totalPages}
            totalElements={logs.data.totalElements}
            onChange={setPage}
          />
        </>
      )}

      {selected && (
        <div className="drawer-backdrop" onClick={() => setSelected(null)}>
          <aside className="drawer" onClick={(e) => e.stopPropagation()}>
            <SectionHead title="Denetim kaydı" />
            <dl className="detail">
              <dt>Zaman</dt>
              <dd>{formatDateTime(selected.createdAt)}</dd>
              <dt>Eylem</dt>
              <dd>{actionLabel(selected.action)}</dd>
              <dt>Eylem kodu</dt>
              <dd className="muted small">{selected.action}</dd>
              <dt>Kim</dt>
              <dd>{selected.userEmail ?? '—'}</dd>
              <dt>IP</dt>
              <dd>{selected.ipAddress ?? '—'}</dd>
              <dt>Ayrıntı</dt>
              <dd>{selected.details ?? '—'}</dd>
            </dl>
            <button className="ghost" onClick={() => setSelected(null)}>
              Kapat
            </button>
          </aside>
        </div>
      )}
    </>
  );
}
