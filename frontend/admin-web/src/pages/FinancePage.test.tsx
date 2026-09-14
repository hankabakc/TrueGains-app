// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { act, cleanup, fireEvent, render, screen } from '@testing-library/react';
import FinancePage from './FinancePage';
import type { AdminPaymentRow, AdminRevenue, PageResponse } from '../api/types';

vi.mock('../api/admin', () => ({
  financeApi: {
    revenue: vi.fn(),
    payments: vi.fn(),
  },
}));
import { financeApi } from '../api/admin';

const mockRevenue: AdminRevenue = {
  revenueToday: 0,
  revenue7d: 0,
  revenue30d: 0,
  revenueTotal: 0,
  successfulPayments: 0,
  failedPayments: 0,
  activeSubscriptions: 0,
  expiringIn7d: 0,
};

const mockPayments: AdminPaymentRow[] = [
  {
    id: 1,
    clientEmail: 'sporcu@test.com',
    amount: 750,
    status: 'SUCCESS',
    transactionDate: '2026-09-03T09:00:00Z',
    packageName: 'Aylık',
  },
  {
    id: 2,
    clientEmail: 'sporcu2@test.com',
    amount: 750,
    status: 'PENDING',
    transactionDate: '2026-09-03T10:00:00Z',
    packageName: 'Aylık',
  },
];

function page<T>(content: T[]): PageResponse<T> {
  return {
    content,
    pageNumber: 0,
    pageSize: 20,
    totalElements: content.length,
    totalPages: 1,
    last: true,
  };
}

beforeEach(() => {
  vi.mocked(financeApi.revenue).mockResolvedValue(mockRevenue);
  vi.mocked(financeApi.payments).mockResolvedValue(page(mockPayments));
});

afterEach(() => {
  cleanup();
  vi.clearAllMocks();
  vi.useRealTimers();
});

describe('FinancePage Bileşen Testleri', () => {
  it('ödeme durumu Türkçe gösterilir', async () => {
    render(<FinancePage />);

    expect(await screen.findByRole('cell', { name: 'Başarılı' })).toBeTruthy();
    expect(screen.getByRole('cell', { name: 'Bekliyor' })).toBeTruthy();
    expect(screen.queryByText('SUCCESS')).toBeNull();
    expect(screen.queryByText('PENDING')).toBeNull();
  });

  it('e-posta ve tarih süzgeci isteğe doğru aralıkla gider', async () => {
    vi.useFakeTimers();
    render(<FinancePage />);
    await vi.advanceTimersByTimeAsync(0);

    fireEvent.change(screen.getByLabelText('Başlangıç tarihi'), { target: { value: '2026-09-01' } });
    fireEvent.change(screen.getByLabelText('Bitiş tarihi'), { target: { value: '2026-09-03' } });
    fireEvent.change(screen.getByPlaceholderText('Kullanıcı e-postası…'), { target: { value: 'sporcu' } });

    await act(async () => {
      await vi.advanceTimersByTimeAsync(300);
    });

    expect(vi.mocked(financeApi.payments).mock.lastCall?.[0]).toMatchObject({
      email: 'sporcu',
      from: new Date(2026, 8, 1).toISOString(),
      to: new Date(2026, 8, 4).toISOString(),
      page: 0,
    });
  });
});
