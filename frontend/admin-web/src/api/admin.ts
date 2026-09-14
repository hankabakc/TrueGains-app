import { deviceId, qs, request } from './client';
import type {
  AdminAuditRow,
  AdminErrors,
  AdminOverview,
  AdminPaymentRow,
  AdminReportRow,
  AdminRevenue,
  AdminSystem,
  AdminUserDetail,
  AdminUserRow,
  AuthResponse,
  PageResponse,
  ReportStatus,
} from './types';

export function login(email: string, password: string) {
  return request<AuthResponse>('/api/v1/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password, deviceId: deviceId() }),
  });
}

export const overviewApi = {
  summary: () => request<AdminOverview>('/api/v1/admin/overview'),
  system: () => request<AdminSystem>('/api/v1/admin/system'),
  errors: () => request<AdminErrors>('/api/v1/admin/errors'),
};

export const usersApi = {
  search: (params: { role?: string; query?: string; active?: boolean | null; page?: number; size?: number }) =>
    request<PageResponse<AdminUserRow>>(`/api/v1/admin/users${qs(params)}`),
  detail: (id: number) => request<AdminUserDetail>(`/api/v1/admin/users/${id}`),
  setActive: (id: number, value: boolean) =>
    request<AdminUserDetail>(`/api/v1/admin/users/${id}/active${qs({ value })}`, { method: 'PATCH' }),
};

export const financeApi = {
  revenue: () => request<AdminRevenue>('/api/v1/admin/finance/revenue'),
  payments: (params: { status?: string; page?: number; size?: number }) =>
    request<PageResponse<AdminPaymentRow>>(`/api/v1/admin/finance/payments${qs(params)}`),
};

export const auditApi = {
  search: (params: { action?: string; email?: string; page?: number; size?: number }) =>
    request<PageResponse<AdminAuditRow>>(`/api/v1/admin/audit${qs(params)}`),
  actions: () => request<string[]>('/api/v1/admin/audit/actions'),
};

export const reportsApi = {
  search: (params: { status?: string; reportedUserId?: number; page?: number; size?: number }) =>
    request<PageResponse<AdminReportRow>>(`/api/v1/admin/reports${qs(params)}`),
  resolve: (id: number, decision: ReportStatus, note?: string, suspendReportedUser = false) =>
    request<AdminReportRow>(`/api/v1/admin/reports/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ decision, note: note ?? null, suspendReportedUser }),
    }),
};
