export type UserRole = 'CLIENT' | 'COACH' | 'ADMIN';

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  timestamp: string;
}

/** Backend PageResponse zarfi. */
export interface PageResponse<T> {
  content: T[];
  pageNumber: number;
  pageSize: number;
  totalElements: number;
  totalPages: number;
  last: boolean;
}

export interface AuthUser {
  id: number;
  externalId: string;
  email: string;
  role: UserRole;
}

export interface AuthResponse {
  user: AuthUser;
  access_token: string;
  token_type: string;
  expires_in: number;
}

export interface AdminOverview {
  totalUsers: number;
  clientCount: number;
  coachCount: number;
  inactiveUsers: number;
  newLast24h: number;
  newLast7d: number;
  newLast30d: number;
  activeLast7d: number;
  pairedClients: number;
  activeSubscriptions: number;
}

export interface AdminSystem {
  uptimeSeconds: number;
  processCpuPercent: number;
  systemCpuPercent: number;
  heapUsedBytes: number;
  heapMaxBytes: number;
  dbActive: number;
  dbIdle: number;
  dbMax: number;
  dbPending: number;
  requestsTotal: number;
  serverErrorsTotal: number;
  clientErrorsTotal: number;
  avgResponseMs: number;
  maxResponseMs: number;
}

export interface AdminUserRow {
  id: number;
  email: string;
  fullName: string | null;
  role: UserRole;
  active: boolean;
  premium: boolean;
  registeredAt: string | null;
  lastLoginAt: string | null;
}

export interface AdminUserDetail extends AdminUserRow {
  phoneNumber: string | null;
  failedLoginAttempts: number | null;
  accountLockedUntil: string | null;
  province: string | null;
  district: string | null;
  experienceYears: number | null;
  specialization: string | null;
  coachId: number | null;
  activeSubscriptions: number;
}

export interface AdminUserExport {
  fileName: string;
  rowCount: number;
  csv: string;
}

export interface AdminRevenue {
  revenueToday: number;
  revenue7d: number;
  revenue30d: number;
  revenueTotal: number;
  successfulPayments: number;
  failedPayments: number;
  activeSubscriptions: number;
  expiringIn7d: number;
}

export interface AdminPaymentRow {
  id: number;
  clientEmail: string | null;
  amount: number;
  status: string;
  transactionDate: string | null;
  packageName: string | null;
}

export interface AdminAuditRow {
  id: number;
  action: string;
  userEmail: string | null;
  ipAddress: string | null;
  details: string | null;
  createdAt: string;
}

export interface AdminIssue {
  id: string;
  title: string;
  culprit: string;
  level: string;
  count: number;
  userCount: number;
  lastSeen: string;
  permalink: string;
  source: 'BACKEND' | 'MOBILE';
}

export interface AdminErrors {
  configured: boolean;
  message: string | null;
  backendIssues: number;
  mobileIssues: number;
  issues: AdminIssue[];
}

export type ReportReason = 'SPAM' | 'HARASSMENT' | 'INAPPROPRIATE_CONTENT' | 'FAKE_PROFILE' | 'SCAM' | 'OTHER';
export type ReportStatus = 'PENDING' | 'ACTIONED' | 'DISMISSED';

export interface AdminReportRow {
  id: number;
  reporterId: number;
  reporterEmail: string | null;
  reportedUserId: number;
  reportedEmail: string | null;
  reason: ReportReason;
  description: string | null;
  status: ReportStatus;
  createdAt: string;
  reviewedAt: string | null;
  reviewedBy: string | null;
  resolutionNote: string | null;
  reportedUserPendingCount: number;
}
