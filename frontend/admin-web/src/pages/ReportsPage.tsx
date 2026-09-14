import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { reportsApi } from '../api/admin';
import { useResource } from '../hooks/useResource';
import type { AdminReportRow, ReportStatus } from '../api/types';
import { Badge, EmptyState, ErrorLine, Loader, Pagination, SectionHead, formatDateTime } from '../components/Ui';

const REASON_LABEL: Record<string, string> = {
  SPAM: 'Spam',
  HARASSMENT: 'Taciz',
  INAPPROPRIATE_CONTENT: 'Uygunsuz içerik',
  FAKE_PROFILE: 'Sahte profil',
  SCAM: 'Dolandırıcılık',
  OTHER: 'Diğer',
};

const STATUS_LABEL: Record<ReportStatus, string> = {
  PENDING: 'bekliyor',
  ACTIONED: 'işlem yapıldı',
  DISMISSED: 'reddedildi',
};

export default function ReportsPage() {
  const [status, setStatus] = useState<string>('PENDING');
  const [page, setPage] = useState(0);
  const [active, setActive] = useState<AdminReportRow | null>(null);
  const [note, setNote] = useState('');
  const [busy, setBusy] = useState(false);
  const [suspend, setSuspend] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);
  const navigate = useNavigate();

  const reports = useResource(
    () => reportsApi.search({ status: status || undefined, page, size: 20 }),
    [status, page],
  );

  async function resolve(decision: ReportStatus, suspendAccount = false) {
    if (!active) return;
    setBusy(true);
    setActionError(null);
    try {
      await reportsApi.resolve(active.id, decision, note || undefined, suspendAccount);
      setActive(null);
      setNote('');
      setSuspend(false);
      await reports.reload();
    } catch (e) {
      // Karar isteği 400 dönebiliyor (askıya alma yalnızca ACTIONED ile, yönetici
      // hesabı kapatılamaz). Sessiz yutulursa yönetici işlemin olduğunu sanır.
      setActionError(e instanceof Error ? e.message : 'Şikâyet karara bağlanamadı.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <SectionHead title="Şikâyetler" />

      <div className="filters">
        <select
          value={status}
          onChange={(e) => {
            setStatus(e.target.value);
            setPage(0);
          }}
        >
          <option value="PENDING">Bekleyenler</option>
          <option value="ACTIONED">İşlem yapılanlar</option>
          <option value="DISMISSED">Reddedilenler</option>
          <option value="">Tümü</option>
        </select>
      </div>

      <ErrorLine text={reports.error} />
      <Loader show={reports.loading && !reports.data} />

      {reports.data && reports.data.content.length === 0 && <EmptyState text="Bu durumda şikâyet yok." />}

      {reports.data && reports.data.content.length > 0 && (
        <>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Tarih</th>
                  <th>Şikâyet edilen</th>
                  <th>Sebep</th>
                  <th>Eden</th>
                  <th>Durum</th>
                </tr>
              </thead>
              <tbody>
                {reports.data.content.map((r) => (
                  <tr
                    key={r.id}
                    className="clickable"
                    onClick={() => {
                      setActive(r);
                      setNote('');
                      setSuspend(false);
                      setActionError(null);
                    }}
                  >
                    <td>{formatDateTime(r.createdAt)}</td>
                    <td>
                      {r.reportedEmail ?? r.reportedUserId}
                      {/* Ayni kisi hakkinda birden fazla bekleyen sikayet, tek tek
                          bakildiginda gorunmez. Sayac o oruntuyu one cikariyor. */}
                      {r.reportedUserPendingCount > 1 && (
                        <Badge tone="bad">{r.reportedUserPendingCount} bekleyen</Badge>
                      )}
                    </td>
                    <td>{REASON_LABEL[r.reason] ?? r.reason}</td>
                    <td className="muted">{r.reporterEmail ?? r.reporterId}</td>
                    <td>
                      <Badge tone={r.status === 'PENDING' ? 'warn' : r.status === 'ACTIONED' ? 'bad' : 'muted'}>
                        {STATUS_LABEL[r.status]}
                      </Badge>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <Pagination
            page={reports.data.pageNumber}
            totalPages={reports.data.totalPages}
            totalElements={reports.data.totalElements}
            onChange={setPage}
          />
        </>
      )}

      {active && (
        <div className="drawer-backdrop" onClick={() => setActive(null)}>
          <aside className="drawer" onClick={(e) => e.stopPropagation()}>
            <SectionHead title="Şikâyet" />
            <dl className="detail">
              <dt>Tarih</dt>
              <dd>{formatDateTime(active.createdAt)}</dd>
              <dt>Şikâyet edilen</dt>
              <dd>{active.reportedEmail ?? active.reportedUserId}</dd>
              <dt>Şikâyet eden</dt>
              <dd>{active.reporterEmail ?? active.reporterId}</dd>
              <dt>Sebep</dt>
              <dd>{REASON_LABEL[active.reason] ?? active.reason}</dd>
              <dt>Açıklama</dt>
              <dd>{active.description || '—'}</dd>
              <dt>Durum</dt>
              <dd>{STATUS_LABEL[active.status]}</dd>
              {active.reviewedBy && (
                <>
                  <dt>Karar veren</dt>
                  <dd>{active.reviewedBy}</dd>
                  <dt>Karar zamanı</dt>
                  <dd>{formatDateTime(active.reviewedAt)}</dd>
                  <dt>Not</dt>
                  <dd>{active.resolutionNote || '—'}</dd>
                </>
              )}
            </dl>

            {/* KR10 → A: hesap işlemleri (pasifleştirme, kilit açma) tek ekranda kalsın. */}
            <button className="ghost" onClick={() => navigate(`/users?id=${active.reportedUserId}`)}>
              Kullanıcı ayrıntısı
            </button>

            <SectionHead title="Geçmiş şikâyetler" />
            <ReportHistory userId={active.reportedUserId} currentId={active.id} />

            {active.status === 'PENDING' && (
              <>
                <div className="field">
                  <label htmlFor="note">Karar notu</label>
                  <input id="note" value={note} onChange={(e) => setNote(e.target.value)} />
                </div>
                <label className="check">
                  <input
                    type="checkbox"
                    checked={suspend}
                    onChange={(e) => setSuspend(e.target.checked)}
                  />
                  Hesabı da pasifleştir
                </label>
                <p className="small muted">
                  İşaretlenirse şikâyet edilen hesap aynı işlemde kapanır. Reddetme kararında
                  uygulanmaz.
                </p>
                <div className="drawer-actions">
                  <button className="danger" disabled={busy} onClick={() => resolve('ACTIONED', suspend)}>
                    İşlem yapıldı
                  </button>
                  <button className="ghost" disabled={busy} onClick={() => resolve('DISMISSED')}>
                    Reddet
                  </button>
                </div>
                <ErrorLine text={actionError} />
              </>
            )}

            <button className="ghost" onClick={() => setActive(null)}>
              Kapat
            </button>
          </aside>
        </div>
      )}
    </>
  );
}

/** Aynı kişinin geçmiş şikâyetleri; çekmece açıkken mount olur, kapanınca gider. */
function ReportHistory({ userId, currentId }: { userId: number; currentId: number }) {
  const history = useResource(
    () => reportsApi.search({ reportedUserId: userId, size: 5 }),
    [userId],
  );

  if (history.loading && !history.data) return <Loader show />;
  if (!history.data || history.data.totalElements <= 1) {
    return <p className="small muted">Bu kullanıcı hakkında başka şikâyet yok.</p>;
  }

  return (
    <>
      <p className="small muted">Toplam {history.data.totalElements} şikâyet (en yeni 5):</p>
      <ul className="history">
        {history.data.content.map((r) => (
          <li key={r.id}>
            <span>
              {formatDateTime(r.createdAt)} · {REASON_LABEL[r.reason] ?? r.reason}
              {r.id === currentId && ' (bu kayıt)'}
            </span>
            <Badge tone={r.status === 'PENDING' ? 'warn' : r.status === 'ACTIONED' ? 'bad' : 'muted'}>
              {STATUS_LABEL[r.status]}
            </Badge>
          </li>
        ))}
      </ul>
    </>
  );
}
