// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { act, cleanup, fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import UsersPage from './UsersPage';
import type { AdminUserDetail, AdminUserRow, PageResponse } from '../api/types';

vi.mock('../api/admin', () => ({
  usersApi: { search: vi.fn(), detail: vi.fn(), setActive: vi.fn(), unlock: vi.fn(), exportCsv: vi.fn() },
}));
import { usersApi } from '../api/admin';

const sampleRow: AdminUserRow = {
  id: 15,
  email: 'antrenor@test.com',
  fullName: null,
  role: 'COACH',
  active: true,
  premium: false,
  registeredAt: null,
  lastLoginAt: null,
};

const sampleDetail: AdminUserDetail = {
  ...sampleRow,
  phoneNumber: null,
  failedLoginAttempts: 0,
  accountLockedUntil: null,
  province: null,
  district: null,
  experienceYears: null,
  specialization: null,
  coachId: null,
  activeSubscriptions: 0,
};

function sayfa(content: AdminUserRow[], total: number): PageResponse<AdminUserRow> {
  return {
    content,
    pageNumber: 0,
    pageSize: 20,
    totalElements: total,
    totalPages: 1,
    last: true,
  };
}

function sayfayiAc(adres = '/users') {
  return render(
    <MemoryRouter initialEntries={[adres]}>
      <UsersPage />
    </MemoryRouter>,
  );
}

beforeEach(() => {
  vi.mocked(usersApi.search).mockResolvedValue(sayfa([sampleRow], 1));
  vi.mocked(usersApi.detail).mockResolvedValue(sampleDetail);
  vi.mocked(usersApi.setActive).mockResolvedValue({ ...sampleDetail, active: false });
  vi.mocked(usersApi.unlock).mockResolvedValue({ ...sampleDetail, failedLoginAttempts: 0, accountLockedUntil: null });
  vi.mocked(usersApi.exportCsv).mockResolvedValue({ fileName: 'kullanicilar-2026-09-14.csv', rowCount: 1, csv: 'x' });
});

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
  vi.useRealTimers();
});

async function satirTikla() {
  await screen.findByText('antrenor@test.com');
  const satirlar = screen.getAllByRole('row').filter((r) => r.className.includes('clickable'));
  fireEvent.click(satirlar[0]);
}

describe('UsersPage Bileşen Testleri', () => {
  it('rol tabloda ve çekmecede Türkçe gösterilir', async () => {
    sayfayiAc();
    expect(await screen.findByRole('cell', { name: 'Antrenör' })).toBeTruthy();

    await satirTikla();
    expect(await screen.findByText('Kullanıcı ayrıntısı')).toBeTruthy();
    expect(screen.queryByText('COACH')).toBeNull();
  });

  it('arama yazılırken istek gecikmeyle bir kez atılır', async () => {
    vi.useFakeTimers();
    sayfayiAc();
    await vi.advanceTimersByTimeAsync(0);
    expect(vi.mocked(usersApi.search)).toHaveBeenCalledTimes(1);

    const input = screen.getByPlaceholderText('E-posta ara…');
    const text = 'antrenor@tes';
    for (let i = 1; i <= text.length; i++) {
      fireEvent.change(input, { target: { value: text.slice(0, i) } });
    }

    await vi.advanceTimersByTimeAsync(299);
    expect(vi.mocked(usersApi.search)).toHaveBeenCalledTimes(1);

    await act(async () => {
      await vi.advanceTimersByTimeAsync(1);
    });
    expect(vi.mocked(usersApi.search)).toHaveBeenCalledTimes(2);
    expect(vi.mocked(usersApi.search).mock.calls[1][0].query).toBe('antrenor@tes');
  });

  it('ayrıntı açılamazsa hata görünür', async () => {
    vi.mocked(usersApi.detail).mockRejectedValue(new Error('Kullanıcı bulunamadı.'));
    sayfayiAc();
    await satirTikla();
    expect(await screen.findByText('Kullanıcı bulunamadı.')).toBeTruthy();
  });

  it('hesap pasifleştirme başarısız olursa çekmecede hata görünür', async () => {
    vi.mocked(usersApi.setActive).mockRejectedValue(new Error('Yönetici hesabı pasifleştirilemez.'));
    sayfayiAc();
    await satirTikla();
    const btn = await screen.findByText('Hesabı pasifleştir');
    fireEvent.click(btn);
    expect(await screen.findByText('Yönetici hesabı pasifleştirilemez.')).toBeTruthy();
  });

  it('adreste id varsa o kullanıcının çekmecesi açık gelir', async () => {
    sayfayiAc('/users?id=15');
    expect(await screen.findByText('Kullanıcı ayrıntısı')).toBeTruthy();
    expect(vi.mocked(usersApi.detail)).toHaveBeenCalledWith(15);
  });

  it('kilitli hesapta kilit açılır ve düğme kaybolur', async () => {
    vi.mocked(usersApi.detail).mockResolvedValue({
      ...sampleDetail,
      failedLoginAttempts: 5,
      accountLockedUntil: '2026-09-14T10:15:00Z',
    });
    sayfayiAc();
    await satirTikla();

    fireEvent.click(await screen.findByText('Kilidi aç ve sayacı sıfırla'));
    await waitFor(() => expect(screen.queryByText('Kilidi aç ve sayacı sıfırla')).toBeNull());
    expect(vi.mocked(usersApi.unlock)).toHaveBeenCalledWith(15);
  });

  it('kilitsiz hesapta kilit açma düğmesi görünmez', async () => {
    sayfayiAc();
    await satirTikla();
    await screen.findByText('Kullanıcı ayrıntısı');
    expect(screen.queryByText('Kilidi aç ve sayacı sıfırla')).toBeNull();
  });

  it('CSV ekrandaki süzgeçlerle istenir ve dosya olarak kaydedilir', async () => {
    const createUrl = vi.fn(() => 'blob:csv');
    URL.createObjectURL = createUrl;
    URL.revokeObjectURL = vi.fn();
    const click = vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(() => {});

    sayfayiAc();
    await screen.findByText('antrenor@test.com');

    fireEvent.change(screen.getAllByRole('combobox')[0], { target: { value: 'COACH' } });
    fireEvent.click(screen.getByText('CSV indir'));

    await waitFor(() => expect(click).toHaveBeenCalledTimes(1));
    expect(vi.mocked(usersApi.exportCsv).mock.calls[0][0]).toEqual({
      role: 'COACH',
      query: undefined,
      active: undefined,
    });
    expect(createUrl).toHaveBeenCalledTimes(1);

    click.mockRestore();
  });

  it('dışa aktarma başarısız olursa hata görünür', async () => {
    vi.mocked(usersApi.exportCsv).mockRejectedValue(new Error('Sunucu hatası (500)'));
    sayfayiAc();
    await screen.findByText('antrenor@test.com');
    fireEvent.click(screen.getByText('CSV indir'));
    expect(await screen.findByText('Sunucu hatası (500)')).toBeTruthy();
  });
});
