import { overviewApi } from '../api/admin';
import { useResource } from '../hooks/useResource';
import { Badge, EmptyState, ErrorLine, Loader, SectionHead, StatCard } from '../components/Ui';

const REFRESH_MS = 60_000;

export default function ErrorsPage() {
  const errors = useResource(() => overviewApi.errors(), [], REFRESH_MS);
  const e = errors.data;

  return (
    <>
      <SectionHead title="Hatalar ve çökmeler" right="son 24 saat" />
      <ErrorLine text={errors.error} />
      <Loader show={errors.loading && !e} />

      {/* Sentry yapilandirilmamissa bu bir HATA degil, bir DURUM. Panel calismaya
          devam eder, eksik olanin ne oldugunu soyler. */}
      {e && !e.configured && <EmptyState text={e.message ?? 'Sentry yapılandırılmamış.'} />}

      {e && e.configured && (
        <>
          <div className="grid">
            <StatCard
              label="Backend"
              value={e.backendIssues.toLocaleString('tr-TR')}
              hint="çözülmemiş"
              tone={e.backendIssues > 0 ? 'bad' : 'ok'}
            />
            <StatCard
              label="Mobil"
              value={e.mobileIssues.toLocaleString('tr-TR')}
              hint="çözülmemiş"
              tone={e.mobileIssues > 0 ? 'bad' : 'ok'}
            />
          </div>

          {e.issues.length === 0 ? (
            <EmptyState text="Son 24 saatte çözülmemiş hata yok." />
          ) : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Hata</th>
                    <th>Kaynak</th>
                    <th>Tekrar</th>
                    <th>Etkilenen</th>
                    <th />
                  </tr>
                </thead>
                <tbody>
                  {e.issues.map((issue) => (
                    <tr key={`${issue.source}-${issue.id}`}>
                      <td>
                        <div>{issue.title}</div>
                        <div className="muted small">{issue.culprit}</div>
                      </td>
                      <td>
                        <Badge tone={issue.source === 'BACKEND' ? 'warn' : 'muted'}>
                          {issue.source === 'BACKEND' ? 'sunucu' : 'mobil'}
                        </Badge>
                      </td>
                      <td>{issue.count.toLocaleString('tr-TR')}</td>
                      <td>{issue.userCount.toLocaleString('tr-TR')}</td>
                      <td>
                        {issue.permalink && (
                          <a href={issue.permalink} target="_blank" rel="noreferrer">
                            Sentry
                          </a>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </>
      )}
    </>
  );
}
