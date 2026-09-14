import type { ApiResponse, AuthUser } from './types';

const TOKEN_KEY = 'gymapp_admin_token';
const DEVICE_KEY = 'gymapp_admin_device';
const EMAIL_KEY = 'gymapp_admin_email';
const USER_KEY = 'gymapp_admin_user';

// sessionStorage bilerek: yonetim jetonu tarayici kapaninca gitsin. localStorage
// olsaydi ortak bir makinede sekme kapatilsa bile oturum acik kalirdi.
export const tokenStore = {
  get: () => sessionStorage.getItem(TOKEN_KEY),
  set: (token: string) => sessionStorage.setItem(TOKEN_KEY, token),
  // Kullanıcı jetonla birlikte gider: biri kalırsa panel yarım oturumla açılırdı.
  clear: () => {
    sessionStorage.removeItem(TOKEN_KEY);
    sessionStorage.removeItem(USER_KEY);
  },
};

/**
 * Giriş yapan yönetici. F5'te jeton dururken giriş ekranı gelmesin diye jetonla aynı
 * depoda. Yalnızca gösterim içindir: yetkiyi sunucu her istekte jetondan denetler.
 */
export const userStore = {
  get: (): AuthUser | null => {
    const raw = sessionStorage.getItem(USER_KEY);
    if (!raw) return null;
    try {
      return JSON.parse(raw) as AuthUser;
    } catch {
      // Bozuk kayıt oturum sayılmaz; giriş ekranı gelir.
      return null;
    }
  },
  set: (user: AuthUser) => sessionStorage.setItem(USER_KEY, JSON.stringify(user)),
};

// Panelin tek bir yoneticisi var; e-postayi her seferinde yazdirmanin anlami yok.
// Parola hatirlanmiyor - onu tarayicinin parola yoneticisi yapsin.
export const rememberedEmail = {
  get: () => localStorage.getItem(EMAIL_KEY),
  set: (email: string) => localStorage.setItem(EMAIL_KEY, email),
  clear: () => localStorage.removeItem(EMAIL_KEY),
};

/** Cihaz kimligi backend'de zorunlu; tarayici basina sabit kalmali. */
export function deviceId(): string {
  let id = localStorage.getItem(DEVICE_KEY);
  if (!id) {
    id = `admin-web-${crypto.randomUUID()}`;
    localStorage.setItem(DEVICE_KEY, id);
  }
  return id;
}

export class ApiError extends Error {
  readonly status: number;

  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

/** Oturum dustugunde tek yerden haberdar olmak icin. */
type UnauthorizedHandler = () => void;
let onUnauthorized: UnauthorizedHandler = () => {};

export function setUnauthorizedHandler(handler: UnauthorizedHandler) {
  onUnauthorized = handler;
}

export async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = tokenStore.get();

  const response = await fetch(path, {
    ...init,
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...init.headers,
    },
  });

  let body: ApiResponse<T> | null = null;
  try {
    body = (await response.json()) as ApiResponse<T>;
  } catch {
    // Govde JSON degilse (vekil hatasi, 502) asagida durum koduyla devam edilir.
  }

  if (!response.ok) {
    // Jeton dusmusse her sayfanin ayri ayri ele almasi gerekmesin.
    if (response.status === 401 || response.status === 403) {
      onUnauthorized();
    }
    throw new ApiError(response.status, body?.message ?? `Sunucu hatası (${response.status})`);
  }
  return body!.data;
}

/** Sorgu dizesi kurar; bos ve tanimsiz degerleri atar. */
export function qs(params: Record<string, string | number | boolean | null | undefined>): string {
  const search = new URLSearchParams();
  for (const [key, value] of Object.entries(params)) {
    if (value !== null && value !== undefined && value !== '') {
      search.set(key, String(value));
    }
  }
  const text = search.toString();
  return text ? `?${text}` : '';
}
