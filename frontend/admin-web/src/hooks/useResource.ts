import { useCallback, useEffect, useState } from 'react';

interface State<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
}

/**
 * Tek bir kaynagi yukler; her sayfada ayni useEffect/try/catch uclemesini
 * tekrarlamamak icin.
 *
 * `refreshMs` verilirse belirtilen araliklarla yeniler. Yenilemede ESKI VERI
 * ekranda kalir: canli izlenen bir panelde her turda ekranin bosalmasi okumayi
 * imkansiz kilar.
 */
export function useResource<T>(loader: () => Promise<T>, deps: unknown[], refreshMs?: number) {
  const [state, setState] = useState<State<T>>({ data: null, loading: true, error: null });

  // deps disaridan geliyor; kancanin sozlesmesi bu.
  // eslint-disable-next-line react-hooks/exhaustive-deps
  const stableLoader = useCallback(loader, deps);

  const reload = useCallback(async () => {
    try {
      const data = await stableLoader();
      setState({ data, loading: false, error: null });
    } catch (e) {
      setState((prev) => ({
        data: prev.data,
        loading: false,
        error: e instanceof Error ? e.message : 'Veri alınamadı.',
      }));
    }
  }, [stableLoader]);

  useEffect(() => {
    let cancelled = false;

    async function run() {
      if (!cancelled) await reload();
    }

    run();

    if (!refreshMs) {
      return () => {
        cancelled = true;
      };
    }

    // Gizli sekmede yoklama yapılmaz: kimse bakmıyorken çekilen veri kimseye
    // görünmüyor, ama /api/v1/admin/** altındaki her istek denetim defterine
    // düşüyor (KURALLAR §1.3). Sekme geri gelince bir kez yenilenir, böylece
    // ekrandaki değer bayat kalmaz.
    const timer = setInterval(() => {
      if (document.visibilityState === 'visible') run();
    }, refreshMs);

    const onVisible = () => {
      if (document.visibilityState === 'visible') run();
    };
    document.addEventListener('visibilitychange', onVisible);

    return () => {
      cancelled = true;
      clearInterval(timer);
      document.removeEventListener('visibilitychange', onVisible);
    };
  }, [reload, refreshMs]);

  return { ...state, reload };
}
