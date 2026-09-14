import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { reportsApi } from './admin';

let fetchMock: ReturnType<typeof vi.fn>;

beforeEach(() => {
  vi.stubGlobal('sessionStorage', { getItem: () => null });
  fetchMock = vi.fn(async () => ({ ok: true, status: 200, json: async () => ({ data: null }) }));
  vi.stubGlobal('fetch', fetchMock);
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe('reportsApi', () => {
  it('resolve ACTIONED kararıyla suspendReportedUser true olarak gönderir', async () => {
    await reportsApi.resolve(7, 'ACTIONED', 'spam', true);

    expect(fetchMock).toHaveBeenCalledOnce();
    const body = JSON.parse(fetchMock.mock.calls[0][1].body);
    expect(body.suspendReportedUser).toBe(true);
    expect(body.decision).toBe('ACTIONED');
    expect(body.note).toBe('spam');
  });

  it('resolve DISMISSED kararında varsayılan olarak suspendReportedUser false gönderir', async () => {
    await reportsApi.resolve(7, 'DISMISSED');

    expect(fetchMock).toHaveBeenCalledOnce();
    const body = JSON.parse(fetchMock.mock.calls[0][1].body);
    expect(body.suspendReportedUser).toBe(false);
    expect(body.decision).toBe('DISMISSED');
  });

  it('search reportedUserId ve size parametreleriyle doğru sorgu dizesini kurar', async () => {
    await reportsApi.search({ reportedUserId: 42, size: 5 });

    expect(fetchMock).toHaveBeenCalledOnce();
    const url = fetchMock.mock.calls[0][0];
    expect(url).toBe('/api/v1/admin/reports?reportedUserId=42&size=5');
  });

  it('search reportedUserId verilmediğinde sorgu dizesinde reportedUserId yer almaz', async () => {
    await reportsApi.search({ status: 'PENDING', page: 0 });

    expect(fetchMock).toHaveBeenCalledOnce();
    const url = fetchMock.mock.calls[0][0];
    expect(url).not.toContain('reportedUserId');
    expect(url).toBe('/api/v1/admin/reports?status=PENDING&page=0');
  });
});
