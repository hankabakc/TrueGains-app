// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, render, screen } from '@testing-library/react';
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom';
import ReportsPage from './ReportsPage';
import type { AdminReportRow, PageResponse } from '../api/types';

vi.mock('../api/admin', () => ({
  reportsApi: { search: vi.fn(), resolve: vi.fn() },
}));
import { reportsApi } from '../api/admin';

function row(id: number, reason: string, status: string): AdminReportRow {
  return {
    id,
    reporterId: 2,
    reporterEmail: 'sporcu@test.com',
    reportedUserId: 15,
    reportedEmail: 'antrenor@test.com',
    reason: reason as AdminReportRow['reason'],
    description: 'test',
    status: status as AdminReportRow['status'],
    createdAt: '2026-09-06T18:48:46Z',
    reviewedAt: null,
    reviewedBy: null,
    resolutionNote: null,
    reportedUserPendingCount: 2,
  };
}

function page(content: AdminReportRow[], total: number): PageResponse<AdminReportRow> {
  return {
    content,
    pageNumber: 0,
    pageSize: 20,
    totalElements: total,
    totalPages: 1,
    last: true,
  };
}

const bekleyenler = [row(21, 'SPAM', 'PENDING'), row(22, 'HARASSMENT', 'PENDING')];
const gecmis = [
  row(22, 'HARASSMENT', 'PENDING'),
  row(21, 'SPAM', 'PENDING'),
  row(20, 'SPAM', 'DISMISSED'),
  row(19, 'SPAM', 'ACTIONED'),
  row(18, 'SPAM', 'DISMISSED'),
];

function AdresGoster() {
  const location = useLocation();
  return <p>adres:{location.pathname + location.search}</p>;
}

function sayfayiAc() {
  return render(
    <MemoryRouter initialEntries={['/reports']}>
      <Routes>
        <Route path="/reports" element={<ReportsPage />} />
        <Route path="/users" element={<AdresGoster />} />
      </Routes>
    </MemoryRouter>,
  );
}

beforeEach(() => {
  vi.mocked(reportsApi.search).mockImplementation(async (p: { reportedUserId?: number }) =>
    p.reportedUserId ? page(gecmis, 6) : page(bekleyenler, 2),
  );
  vi.mocked(reportsApi.resolve).mockResolvedValue(bekleyenler[0]);
});

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});

async function cekmeceyiAc(sira: number) {
  await screen.findAllByText('antrenor@test.com');
  const satirlar = screen.getAllByRole('row').filter((r) => r.className.includes('clickable'));
  fireEvent.click(satirlar[sira]);
}

describe('ReportsPage Çekmece ve Karar Bileşen Testleri', () => {
  it('kutu işaretliyken "İşlem yapıldı" tıklandığında suspendReportedUser true olarak gönderilir', async () => {
    sayfayiAc();
    await cekmeceyiAc(0);
    fireEvent.click(screen.getByLabelText('Hesabı da pasifleştir'));
    fireEvent.change(screen.getByLabelText('Karar notu'), { target: { value: 'not' } });
    fireEvent.click(screen.getByText('İşlem yapıldı'));
    expect(vi.mocked(reportsApi.resolve).mock.calls[0]).toEqual([21, 'ACTIONED', 'not', true]);
  });

  it('kutu işaretliyken "Reddet" tıklandığında suspendReportedUser false olarak gönderilir', async () => {
    // Kutu işaretliyken false gitmezse backend 400 döner ve şikâyet reddedilemez.
    sayfayiAc();
    await cekmeceyiAc(1);
    fireEvent.click(screen.getByLabelText('Hesabı da pasifleştir'));
    fireEvent.click(screen.getByText('Reddet'));
    expect(vi.mocked(reportsApi.resolve).mock.calls[0]).toEqual([22, 'DISMISSED', undefined, false]);
  });

  it('karar isteği başarısız olursa çekmecede hata görünür', async () => {
    vi.mocked(reportsApi.resolve).mockRejectedValue(new Error('Şikâyet karara bağlanamadı.'));
    sayfayiAc();
    await cekmeceyiAc(0);
    fireEvent.click(screen.getByText('İşlem yapıldı'));
    expect(await screen.findByText('Şikâyet karara bağlanamadı.')).toBeTruthy();
  });

  it('çekmece geçmiş şikâyetler listesini ve bu kayıt etiketini gösterir', async () => {
    const { container } = sayfayiAc();
    await cekmeceyiAc(0);
    await screen.findByText('Toplam 6 şikâyet (en yeni 5):');
    expect(container.textContent).toContain('(bu kayıt)');
  });

  it('kullanıcı ayrıntısı düğmesi Kullanıcılar sayfasına o kişiyle gider', async () => {
    sayfayiAc();
    await cekmeceyiAc(0);
    fireEvent.click(screen.getByText('Kullanıcı ayrıntısı'));
    expect(await screen.findByText('adres:/users?id=15')).toBeTruthy();
  });
});
