// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { act, cleanup, fireEvent, render, screen } from '@testing-library/react';
import UsersPage from './UsersPage';
import type { AdminUserDetail, AdminUserRow, PageResponse } from '../api/types';

vi.mock('../api/admin', () => ({
  usersApi: { search: vi.fn(), detail: vi.fn(), setActive: vi.fn() },
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

beforeEach(() => {
  vi.mocked(usersApi.search).mockResolvedValue(sayfa([sampleRow], 1));
  vi.mocked(usersApi.detail).mockResolvedValue(sampleDetail);
  vi.mocked(usersApi.setActive).mockResolvedValue({ ...sampleDetail, active: false });
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
    render(<UsersPage />);
    expect(await screen.findByRole('cell', { name: 'Antrenör' })).toBeTruthy();

    await satirTikla();
    expect(await screen.findByText('Kullanıcı ayrıntısı')).toBeTruthy();
    expect(screen.queryByText('COACH')).toBeNull();
  });

  it('arama yazılırken istek gecikmeyle bir kez atılır', async () => {
    vi.useFakeTimers();
    render(<UsersPage />);
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
    render(<UsersPage />);
    await satirTikla();
    expect(await screen.findByText('Kullanıcı bulunamadı.')).toBeTruthy();
  });

  it('hesap pasifleştirme başarısız olursa çekmecede hata görünür', async () => {
    vi.mocked(usersApi.setActive).mockRejectedValue(new Error('Yönetici hesabı pasifleştirilemez.'));
    render(<UsersPage />);
    await satirTikla();
    const btn = await screen.findByText('Hesabı pasifleştir');
    fireEvent.click(btn);
    expect(await screen.findByText('Yönetici hesabı pasifleştirilemez.')).toBeTruthy();
  });
});
