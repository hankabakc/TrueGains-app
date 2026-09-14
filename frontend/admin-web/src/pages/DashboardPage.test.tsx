// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { cleanup, render, screen } from '@testing-library/react';
import DashboardPage from './DashboardPage';
import type { AdminOverview, AdminSystem } from '../api/types';

vi.mock('../api/admin', () => ({
  overviewApi: {
    system: vi.fn(),
    summary: vi.fn(),
    errors: vi.fn(),
  },
}));
import { overviewApi } from '../api/admin';

const mockSystem: AdminSystem = {
  uptimeSeconds: 0,
  processCpuPercent: 0,
  systemCpuPercent: 0,
  heapUsedBytes: 0,
  heapMaxBytes: 0,
  dbActive: 0,
  dbIdle: 0,
  dbMax: 0,
  dbPending: 0,
  requestsTotal: 100,
  serverErrorsTotal: 2,
  clientErrorsTotal: 5,
  avgResponseMs: 94,
  maxResponseMs: 75,
};

const mockSummary: AdminOverview = {
  totalUsers: 0,
  clientCount: 0,
  coachCount: 0,
  inactiveUsers: 0,
  newLast24h: 0,
  newLast7d: 0,
  newLast30d: 0,
  activeLast7d: 0,
  pairedClients: 0,
  activeSubscriptions: 0,
};

beforeEach(() => {
  vi.mocked(overviewApi.system).mockResolvedValue(mockSystem);
  vi.mocked(overviewApi.summary).mockResolvedValue(mockSummary);
});

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});

const kart = (etiket: string) => screen.getByText(etiket).closest('.card')?.textContent ?? '';

describe('DashboardPage', () => {
  it('sayaçlar ve yanıt süreleri pencereleriyle gösterilir', async () => {
    render(<DashboardPage />);

    await screen.findByText('En yüksek yanıt');

    const enYuksek = kart('En yüksek yanıt');
    expect(enYuksek).toContain('75 ms');
    expect(enYuksek).toContain('son 2 dakika');

    const ortalama = kart('Ortalama yanıt');
    expect(ortalama).toContain('94 ms');
    expect(ortalama).toContain('açılıştan beri');
    expect(ortalama.toLowerCase()).not.toContain('en yüksek');

    const sunucu = kart('Sunucu hatası');
    expect(sunucu).toContain('açılıştan beri');

    const istemci = kart('İstemci hatası');
    expect(istemci).toContain('açılıştan beri');
  });
});
