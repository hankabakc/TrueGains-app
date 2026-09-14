// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { cleanup, render } from '@testing-library/react';
import { useResource } from './useResource';

function gorunurluk(deger: 'visible' | 'hidden') {
  Object.defineProperty(document, 'visibilityState', { value: deger, configurable: true });
}

function Sonda({ loader }: { loader: () => Promise<string> }) {
  const { data } = useResource(loader, [], 10_000);
  return <div>{data}</div>;
}

describe('useResource Arka Plan Yoklama Kancası', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    cleanup();
    vi.useRealTimers();
    vi.clearAllMocks();
  });

  it('ilk yükleme sekme gizli olsa bile her durumda yapılır', async () => {
    gorunurluk('hidden');
    const loader = vi.fn().mockResolvedValue('veri');
    render(<Sonda loader={loader} />);
    await vi.advanceTimersByTimeAsync(0);
    expect(loader).toHaveBeenCalledTimes(1);
  });

  it('sekme gizliyken zamanlayıcı tikleri atlanır', async () => {
    gorunurluk('hidden');
    const loader = vi.fn().mockResolvedValue('veri');
    render(<Sonda loader={loader} />);
    await vi.advanceTimersByTimeAsync(0);
    expect(loader).toHaveBeenCalledTimes(1);

    await vi.advanceTimersByTimeAsync(30_000);
    expect(loader).toHaveBeenCalledTimes(1);
  });

  it('sekme görünürken zamanlayıcı tikleri çalışır', async () => {
    gorunurluk('visible');
    const loader = vi.fn().mockResolvedValue('veri');
    render(<Sonda loader={loader} />);
    await vi.advanceTimersByTimeAsync(0);
    expect(loader).toHaveBeenCalledTimes(1);

    await vi.advanceTimersByTimeAsync(30_000);
    expect(loader).toHaveBeenCalledTimes(4);
  });

  it('sekme geri görünür olunca bir kez yenilenir', async () => {
    gorunurluk('hidden');
    const loader = vi.fn().mockResolvedValue('veri');
    render(<Sonda loader={loader} />);
    await vi.advanceTimersByTimeAsync(0);
    expect(loader).toHaveBeenCalledTimes(1);

    gorunurluk('visible');
    document.dispatchEvent(new Event('visibilitychange'));
    await vi.advanceTimersByTimeAsync(0);
    expect(loader).toHaveBeenCalledTimes(2);
  });

  it('sekme gizlenirken istek atılmaz', async () => {
    gorunurluk('visible');
    const loader = vi.fn().mockResolvedValue('veri');
    render(<Sonda loader={loader} />);
    await vi.advanceTimersByTimeAsync(0);
    expect(loader).toHaveBeenCalledTimes(1);

    gorunurluk('hidden');
    document.dispatchEvent(new Event('visibilitychange'));
    await vi.advanceTimersByTimeAsync(0);
    expect(loader).toHaveBeenCalledTimes(1);
  });
});

