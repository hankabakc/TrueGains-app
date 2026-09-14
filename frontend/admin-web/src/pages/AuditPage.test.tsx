// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { act, cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import AuditPage from './AuditPage';
import type { AdminAuditRow, PageResponse } from '../api/types';

vi.mock('../api/admin', () => ({
  auditApi: { search: vi.fn(), actions: vi.fn() },
}));
import { auditApi } from '../api/admin';

const sampleRow: AdminAuditRow = {
  id: 1,
  action: 'ADMIN_REPORT_RESOLVE',
  userEmail: 'yonetici@test.com',
  ipAddress: '172.20.0.1',
  details: 'reportId=22 decision=ACTIONED reportedUserId=15 suspended=true',
  createdAt: '2026-09-06T19:26:00Z',
};

function sayfa(content: AdminAuditRow[], total: number): PageResponse<AdminAuditRow> {
  return {
    content,
    pageNumber: 0,
    pageSize: 50,
    totalElements: total,
    totalPages: 1,
    last: true,
  };
}

beforeEach(() => {
  vi.mocked(auditApi.actions).mockResolvedValue(['ADMIN_ACCESS', 'ADMIN_REPORT_RESOLVE']);
  vi.mocked(auditApi.search).mockResolvedValue(sayfa([sampleRow], 1));
});

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
  vi.useRealTimers();
});

async function satirTikla() {
  await screen.findByText('yonetici@test.com');
  const satirlar = screen.getAllByRole('row').filter((r) => r.className.includes('clickable'));
  fireEvent.click(satirlar[0]);
}

describe('AuditPage Bileşen Testleri', () => {
  it('eylem tabloda ve süzgeçte Türkçe gösterilir', async () => {
    render(<AuditPage />);
    expect(await screen.findByRole('cell', { name: 'Şikâyet karara bağlandı' })).toBeTruthy();
    expect(await screen.findByRole('option', { name: 'Panel erişimi' })).toBeTruthy();
  });

  it('e-posta aranırken istek gecikmeyle bir kez atılır', async () => {
    vi.useFakeTimers();
    render(<AuditPage />);
    await vi.advanceTimersByTimeAsync(0);
    expect(vi.mocked(auditApi.search)).toHaveBeenCalledTimes(1);

    const input = screen.getByPlaceholderText('E-posta…');
    const text = 'yonetici@tes';
    for (let i = 1; i <= text.length; i++) {
      fireEvent.change(input, { target: { value: text.slice(0, i) } });
    }

    await vi.advanceTimersByTimeAsync(299);
    expect(vi.mocked(auditApi.search)).toHaveBeenCalledTimes(1);

    await act(async () => {
      await vi.advanceTimersByTimeAsync(1);
    });
    expect(vi.mocked(auditApi.search)).toHaveBeenCalledTimes(2);
    expect(vi.mocked(auditApi.search).mock.calls[1][0].email).toBe('yonetici@tes');
  });

  it('satıra tıklanınca ayrıntı çekmecede tam açılır', async () => {
    render(<AuditPage />);
    await satirTikla();
    expect(await screen.findByText('Denetim kaydı')).toBeTruthy();
    const details = screen.getAllByText('reportId=22 decision=ACTIONED reportedUserId=15 suspended=true');
    expect(details.length).toBe(2);
    expect(vi.mocked(auditApi.search)).toHaveBeenCalledTimes(1);
  });

  it('tarih aralığı süzgeci isteğe ISO anı olarak gider', async () => {
    render(<AuditPage />);
    await screen.findByText('yonetici@test.com');

    fireEvent.change(screen.getByLabelText('Başlangıç zamanı'), { target: { value: '2026-09-06T18:00' } });
    fireEvent.change(screen.getByLabelText('Bitiş zamanı'), { target: { value: '2026-09-06T19:00' } });

    await waitFor(() =>
      expect(vi.mocked(auditApi.search).mock.lastCall?.[0]).toMatchObject({
        from: new Date(2026, 8, 6, 18, 0).toISOString(),
        to: new Date(2026, 8, 6, 19, 0).toISOString(),
        page: 0,
      }),
    );
  });
});
