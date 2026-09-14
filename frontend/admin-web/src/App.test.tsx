// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from 'vitest';
import { cleanup, fireEvent, render, screen } from '@testing-library/react';
import App from './App';

// Panel açılınca DashboardPage sunucuya gider (10 sn'de bir). Sonuçlanmayan söz verilir:
// ekran yüklemede bekler, durum güncellemesi olmaz.
vi.mock('./api/admin', () => ({
  login: vi.fn(),
  overviewApi: {
    summary: vi.fn(() => new Promise(() => {})),
    system: vi.fn(() => new Promise(() => {})),
    errors: vi.fn(() => new Promise(() => {})),
  },
}));
import { login } from './api/admin';

const ADMIN = { id: 1, externalId: 'ext-1', email: 'yonetici@test.com', role: 'ADMIN' as const };

function oturumKur(user: string | null) {
  sessionStorage.setItem('gymapp_admin_token', 'jeton');
  if (user !== null) sessionStorage.setItem('gymapp_admin_user', user);
}

describe('App Bileşen Testleri', () => {
  afterEach(() => {
    cleanup();
    sessionStorage.clear();
    localStorage.clear();
    vi.clearAllMocks();
  });

  it('geçerli oturum varken yenilenen sayfa paneli açar', () => {
    oturumKur(JSON.stringify(ADMIN));
    render(<App />);
    expect(screen.getByText('yonetici@test.com')).toBeTruthy();
    expect(screen.queryByText('Yönetim Paneli')).toBeNull();
  });

  it('jeton yoksa kayıtlı kullanıcı olsa da giriş ekranı gelir', () => {
    sessionStorage.setItem('gymapp_admin_user', JSON.stringify(ADMIN));
    render(<App />);
    expect(screen.getByText('Yönetim Paneli')).toBeTruthy();
  });

  it('bozuk kullanıcı kaydında giriş ekranı gelir', () => {
    oturumKur('{bozuk');
    render(<App />);
    expect(screen.getByText('Yönetim Paneli')).toBeTruthy();
  });

  it('çıkışta jeton ve kullanıcı birlikte silinir', () => {
    oturumKur(JSON.stringify(ADMIN));
    render(<App />);
    fireEvent.click(screen.getByText('Çıkış'));
    expect(screen.getByText('Yönetim Paneli')).toBeTruthy();
    expect(sessionStorage.getItem('gymapp_admin_token')).toBeNull();
    expect(sessionStorage.getItem('gymapp_admin_user')).toBeNull();
  });

  it('girişten sonra sayfa yenilense de panel açık kalır', async () => {
    vi.mocked(login).mockResolvedValue({
      user: ADMIN,
      access_token: 'jeton',
      token_type: 'Bearer',
      expires_in: 900,
    });
    render(<App />);
    fireEvent.change(screen.getByLabelText('E-posta'), { target: { value: 'yonetici@test.com' } });
    fireEvent.change(screen.getByLabelText('Parola'), { target: { value: 'Parola123!' } });
    fireEvent.click(screen.getByText('Aç'));
    expect(await screen.findByText('yonetici@test.com')).toBeTruthy();
    cleanup();
    render(<App />);
    expect(screen.getByText('yonetici@test.com')).toBeTruthy();
  });
});
