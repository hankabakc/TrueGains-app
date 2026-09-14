import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { usersApi } from '../api/admin';
import { useResource } from '../hooks/useResource';
import { SEARCH_DEBOUNCE_MS, useDebouncedValue } from '../hooks/useDebouncedValue';
import type { AdminUserDetail, UserRole } from '../api/types';
import { Badge, EmptyState, ErrorLine, Loader, Pagination, SectionHead, formatDateTime } from '../components/Ui';

const ROLE_LABEL: Record<UserRole, string> = {
  CLIENT: 'Sporcu',
  COACH: 'Antrenör',
  ADMIN: 'Yönetici',
};

const ROLES = [
  { value: '', label: 'Tüm roller' },
  ...(Object.keys(ROLE_LABEL) as UserRole[]).map((value) => ({ value, label: ROLE_LABEL[value] })),
];

/**
 * CSV sunucudan zarfın içinde metin olarak geliyor; dosyayı tarayıcı oluşturur. BOM: Excel
 * Türkçe harfleri doğru okusun.
 */
function saveCsv(fileName: string, csv: string) {
  const url = URL.createObjectURL(new Blob(['\uFEFF', csv], { type: 'text/csv;charset=utf-8' }));
  const link = document.createElement('a');
  link.href = url;
  link.download = fileName;
  link.click();
  URL.revokeObjectURL(url);
}

export default function UsersPage() {
  const [role, setRole] = useState('');
  const [query, setQuery] = useState('');
  const debouncedQuery = useDebouncedValue(query, SEARCH_DEBOUNCE_MS);
  const [activeFilter, setActiveFilter] = useState<'' | 'true' | 'false'>('');
  const [page, setPage] = useState(0);
  const [selected, setSelected] = useState<AdminUserDetail | null>(null);
  const [busy, setBusy] = useState(false);
  const [detailError, setDetailError] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [exporting, setExporting] = useState(false);
  const [exportError, setExportError] = useState<string | null>(null);
  const [searchParams, setSearchParams] = useSearchParams();
  const linkedUserId = Number(searchParams.get('id'));

  const users = useResource(
    () =>
      usersApi.search({
        role: role || undefined,
        query: debouncedQuery || undefined,
        active: activeFilter === '' ? undefined : activeFilter === 'true',
        page,
        size: 20,
      }),
    [role, debouncedQuery, activeFilter, page],
  );

  async function openDetail(id: number) {
    setDetailError(null);
    setActionError(null);
    try {
      setSelected(await usersApi.detail(id));
    } catch (e) {
      // Ayrıntı açılmazsa tıklama hiçbir şey yapmamış gibi görünür.
      setDetailError(e instanceof Error ? e.message : 'Kullanıcı ayrıntısı alınamadı.');
    }
  }

  // Şikâyetler ekranından gelinirse (KR10 → A) o kullanıcının çekmecesi açık gelir.
  useEffect(() => {
    if (Number.isInteger(linkedUserId) && linkedUserId > 0) {
      void openDetail(linkedUserId);
    }
  }, [linkedUserId]);

  function closeDetail() {
    setSelected(null);
    // Adres temizlenmezse sayfa yenilenince çekmece yeniden açılır.
    if (searchParams.has('id')) {
      setSearchParams({}, { replace: true });
    }
  }

  async function toggleActive(user: AdminUserDetail) {
    setBusy(true);
    setActionError(null);
    try {
      setSelected(await usersApi.setActive(user.id, !user.active));
      await users.reload();
    } catch (e) {
      // Sessiz kalırsa düğme eski hâlinde durur ve yönetici işlemin yapıldığını sanır.
      setActionError(e instanceof Error ? e.message : 'Hesap durumu değiştirilemedi.');
    } finally {
      setBusy(false);
    }
  }

  async function unlock(user: AdminUserDetail) {
    setBusy(true);
    setActionError(null);
    try {
      setSelected(await usersApi.unlock(user.id));
    } catch (e) {
      setActionError(e instanceof Error ? e.message : 'Hesap kilidi açılamadı.');
    } finally {
      setBusy(false);
    }
  }

  async function exportCsv() {
    setExporting(true);
    setExportError(null);
    try {
      const result = await usersApi.exportCsv({
        role: role || undefined,
        query: debouncedQuery || undefined,
        active: activeFilter === '' ? undefined : activeFilter === 'true',
      });
      saveCsv(result.fileName, result.csv);
    } catch (e) {
      setExportError(e instanceof Error ? e.message : 'Dışa aktarma yapılamadı.');
    } finally {
      setExporting(false);
    }
  }

  return (
    <>
      <SectionHead title="Kullanıcılar" />

      <div className="filters">
        <input
          placeholder="E-posta ara…"
          value={query}
          onChange={(e) => {
            setQuery(e.target.value);
            setPage(0);
          }}
        />
        <select
          value={role}
          onChange={(e) => {
            setRole(e.target.value);
            setPage(0);
          }}
        >
          {ROLES.map((r) => (
            <option key={r.value} value={r.value}>
              {r.label}
            </option>
          ))}
        </select>
        <select
          value={activeFilter}
          onChange={(e) => {
            setActiveFilter(e.target.value as '' | 'true' | 'false');
            setPage(0);
          }}
        >
          <option value="">Aktif + pasif</option>
          <option value="true">Yalnızca aktif</option>
          <option value="false">Yalnızca pasif</option>
        </select>
        <button className="ghost" disabled={exporting} onClick={exportCsv}>
          {exporting ? 'Hazırlanıyor…' : 'CSV indir'}
        </button>
      </div>

      {/* Isimler AES sifreli oldugu icin SQL'de aranamiyor; arama e-posta uzerinden. */}
      <p className="muted hint-line">Arama e-posta üzerinden yapılır; isimler şifreli saklandığı için aranamaz. CSV ekrandaki süzgeçlerle iner ve denetim defterine yazılır.</p>

      <ErrorLine text={users.error} />
      <ErrorLine text={detailError} />
      <ErrorLine text={exportError} />
      <Loader show={users.loading && !users.data} />

      {users.data && users.data.content.length === 0 && <EmptyState text="Kayıt bulunamadı." />}

      {users.data && users.data.content.length > 0 && (
        <>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>E-posta</th>
                  <th>Ad</th>
                  <th>Rol</th>
                  <th>Durum</th>
                  <th>Kayıt</th>
                  <th>Son giriş</th>
                </tr>
              </thead>
              <tbody>
                {users.data.content.map((u) => (
                  <tr key={u.id} onClick={() => openDetail(u.id)} className="clickable">
                    <td>{u.email}</td>
                    <td>{u.fullName ?? '—'}</td>
                    <td>{ROLE_LABEL[u.role] ?? u.role}</td>
                    <td>
                      {u.active ? <Badge tone="ok">aktif</Badge> : <Badge tone="bad">pasif</Badge>}
                      {u.premium && <Badge tone="warn">premium</Badge>}
                    </td>
                    <td>{formatDateTime(u.registeredAt)}</td>
                    <td>{formatDateTime(u.lastLoginAt)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <Pagination
            page={users.data.pageNumber}
            totalPages={users.data.totalPages}
            totalElements={users.data.totalElements}
            onChange={setPage}
          />
        </>
      )}

      {selected && (
        <div className="drawer-backdrop" onClick={closeDetail}>
          <aside className="drawer" onClick={(e) => e.stopPropagation()}>
            <SectionHead title="Kullanıcı ayrıntısı" />
            <dl className="detail">
              <dt>E-posta</dt>
              <dd>{selected.email}</dd>
              <dt>Ad</dt>
              <dd>{selected.fullName ?? '—'}</dd>
              <dt>Telefon</dt>
              <dd>{selected.phoneNumber ?? '—'}</dd>
              <dt>Rol</dt>
              <dd>{ROLE_LABEL[selected.role] ?? selected.role}</dd>
              <dt>Durum</dt>
              <dd>{selected.active ? 'aktif' : 'pasif'}</dd>
              <dt>Kayıt</dt>
              <dd>{formatDateTime(selected.registeredAt)}</dd>
              <dt>Son giriş</dt>
              <dd>{formatDateTime(selected.lastLoginAt)}</dd>
              <dt>Başarısız giriş</dt>
              <dd>{selected.failedLoginAttempts ?? 0}</dd>
              <dt>Kilitli</dt>
              <dd>{selected.accountLockedUntil ? formatDateTime(selected.accountLockedUntil) : 'hayır'}</dd>
              {selected.role === 'COACH' && (
                <>
                  <dt>Konum</dt>
                  <dd>{[selected.province, selected.district].filter(Boolean).join(', ') || '—'}</dd>
                  <dt>Deneyim</dt>
                  <dd>{selected.experienceYears ? `${selected.experienceYears} yıl` : '—'}</dd>
                  <dt>Uzmanlık</dt>
                  <dd>{selected.specialization ?? '—'}</dd>
                </>
              )}
              {selected.role === 'CLIENT' && (
                <>
                  <dt>Antrenör</dt>
                  <dd>{selected.coachId ?? '—'}</dd>
                  <dt>Aktif abonelik</dt>
                  <dd>{selected.activeSubscriptions}</dd>
                </>
              )}
            </dl>

            <p className="muted">
              Bu ekranı açmak denetim defterine kaydedildi. Hesap silme burada yok: geri alınamaz.
            </p>

            <div className="drawer-actions">
              {(selected.accountLockedUntil !== null || (selected.failedLoginAttempts ?? 0) > 0) && (
                <button disabled={busy} onClick={() => unlock(selected)}>
                  Kilidi aç ve sayacı sıfırla
                </button>
              )}
              <button
                className={selected.active ? 'danger' : ''}
                disabled={busy}
                onClick={() => toggleActive(selected)}
              >
                {selected.active ? 'Hesabı pasifleştir' : 'Hesabı etkinleştir'}
              </button>
              <button className="ghost" onClick={closeDetail}>
                Kapat
              </button>
            </div>
            <ErrorLine text={actionError} />
          </aside>
        </div>
      )}
    </>
  );
}
