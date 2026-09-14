import { overviewApi } from '../api/admin';
import { useResource } from '../hooks/useResource';
import { ErrorLine, Loader, SectionHead, StatCard, type Tone } from '../components/Ui';

const REFRESH_MS = 10_000;

function formatUptime(seconds: number): string {
  if (seconds <= 0) return '—';
  const d = Math.floor(seconds / 86400);
  const h = Math.floor((seconds % 86400) / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  if (d > 0) return `${d}g ${h}s`;
  if (h > 0) return `${h}s ${m}dk`;
  return `${m}dk`;
}

function formatBytes(bytes: number): string {
  if (bytes <= 0) return '—';
  const mb = bytes / 1024 / 1024;
  return mb >= 1024 ? `${(mb / 1024).toFixed(1)} GB` : `${Math.round(mb)} MB`;
}

function threshold(value: number, warn: number, bad: number): Tone {
  if (value >= bad) return 'bad';
  if (value >= warn) return 'warn';
  return 'ok';
}

export default function DashboardPage() {
  const system = useResource(() => overviewApi.system(), [], REFRESH_MS);
  const overview = useResource(() => overviewApi.summary(), [], REFRESH_MS);

  const s = system.data;
  const o = overview.data;

  const heapPercent = s && s.heapMaxBytes > 0 ? (s.heapUsedBytes / s.heapMaxBytes) * 100 : 0;

  return (
    <>
      <SectionHead
        title="Sunucu durumu"
        right={system.error ? system.error : new Date().toLocaleTimeString('tr-TR')}
      />
      <Loader show={system.loading && !s} />

      {s && (
        <div className="grid">
          <StatCard label="Çalışma süresi" value={formatUptime(s.uptimeSeconds)} />
          <StatCard
            label="Bellek"
            value={`${Math.round(heapPercent)}%`}
            hint={`${formatBytes(s.heapUsedBytes)} / ${formatBytes(s.heapMaxBytes)}`}
            tone={threshold(heapPercent, 70, 85)}
          />
          <StatCard label="CPU (süreç)" value={`${s.processCpuPercent}%`} hint={`sistem ${s.systemCpuPercent}%`} />
          <StatCard
            label="Veritabanı havuzu"
            value={`${s.dbActive} / ${s.dbMax}`}
            hint={s.dbPending > 0 ? `${s.dbPending} istek bekliyor` : `${s.dbIdle} boşta`}
            tone={s.dbPending > 0 ? 'bad' : 'ok'}
          />
          <StatCard label="Toplam istek" value={s.requestsTotal.toLocaleString('tr-TR')} hint="açılıştan beri" />
          <StatCard
            label="Sunucu hatası"
            value={s.serverErrorsTotal.toLocaleString('tr-TR')}
            hint="5xx · açılıştan beri"
            tone={s.serverErrorsTotal > 0 ? 'bad' : 'ok'}
          />
          <StatCard label="İstemci hatası" value={s.clientErrorsTotal.toLocaleString('tr-TR')} hint="4xx · açılıştan beri" />
          <StatCard
            label="Ortalama yanıt"
            value={`${Math.round(s.avgResponseMs)} ms`}
            hint="açılıştan beri"
            tone={threshold(s.avgResponseMs, 200, 500)}
          />
          {/* Micrometer'da en yüksek değer kayan pencereli (varsayılan 2 dk), ortalama ise
              açılıştan beri birikiyor. Tek kartta durunca "ortalama > en yüksek" gibi imkânsız
              görünen bir sayı çıkıyordu. */}
          <StatCard label="En yüksek yanıt" value={`${Math.round(s.maxResponseMs)} ms`} hint="son 2 dakika" />
        </div>
      )}

      <SectionHead title="Kullanıcılar" />
      <ErrorLine text={overview.error} />
      <Loader show={overview.loading && !o} />

      {o && (
        <>
          <div className="grid">
            <StatCard label="Toplam kullanıcı" value={o.totalUsers.toLocaleString('tr-TR')} />
            <StatCard label="Sporcu" value={o.clientCount.toLocaleString('tr-TR')} />
            <StatCard label="Antrenör" value={o.coachCount.toLocaleString('tr-TR')} />
            <StatCard
              label="Pasif hesap"
              value={o.inactiveUsers.toLocaleString('tr-TR')}
              tone={o.inactiveUsers > 0 ? 'warn' : 'ok'}
            />
          </div>

          <SectionHead title="Büyüme" />
          <div className="grid">
            <StatCard label="Yeni kayıt" value={o.newLast24h.toLocaleString('tr-TR')} hint="son 24 saat" />
            <StatCard label="Yeni kayıt" value={o.newLast7d.toLocaleString('tr-TR')} hint="son 7 gün" />
            <StatCard label="Yeni kayıt" value={o.newLast30d.toLocaleString('tr-TR')} hint="son 30 gün" />
            <StatCard label="Giriş yapan" value={o.activeLast7d.toLocaleString('tr-TR')} hint="son 7 gün" />
          </div>

          <SectionHead title="Eşleşme ve abonelik" />
          <div className="grid">
            <StatCard label="Antrenörü olan sporcu" value={o.pairedClients.toLocaleString('tr-TR')} />
            <StatCard label="Aktif abonelik" value={o.activeSubscriptions.toLocaleString('tr-TR')} />
          </div>
        </>
      )}
    </>
  );
}
