import { useState, type FormEvent } from 'react';
import { login } from '../api/admin';
import { rememberedEmail, tokenStore, userStore } from '../api/client';
import type { AuthUser } from '../api/types';

interface Props {
  onSignedIn: (user: AuthUser) => void;
}

export default function LoginPage({ onSignedIn }: Props) {
  const saved = rememberedEmail.get();

  const [email, setEmail] = useState(saved ?? '');
  const [editingEmail, setEditingEmail] = useState(saved === null);
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);

    try {
      const auth = await login(email.trim(), password);

      // Backend zaten /api/v1/admin/** ucunu ADMIN'e kilitliyor. Buradaki kontrol
      // ek guvenlik degil, dogru geri bildirim: yetkisiz hesapla giren kisi bos
      // bir panel yerine sebebini gorsun.
      if (auth.user.role !== 'ADMIN') {
        setError('Bu hesabın yönetim yetkisi yok.');
        return;
      }

      rememberedEmail.set(auth.user.email);
      tokenStore.set(auth.access_token);
      userStore.set(auth.user);
      onSignedIn(auth.user);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Giriş yapılamadı.');
    } finally {
      setBusy(false);
    }
  }

  function useDifferentAccount() {
    rememberedEmail.clear();
    setEmail('');
    setEditingEmail(true);
  }

  return (
    <div className="login-shell">
      <form className="gate" onSubmit={submit}>
        <div className="gate-lock" aria-hidden="true">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <rect x="4" y="10" width="16" height="10" rx="2" />
            <path d="M8 10V7a4 4 0 0 1 8 0v3" />
          </svg>
        </div>

        <h1>Yönetim Paneli</h1>
        <p className="sub">Yetkili erişim</p>

        {error && <p className="error">{error}</p>}

        {/* Hatirlanan e-posta EKRANDA GOSTERILMIYOR: tek yonetici varken bilgi
            degeri yok, ama paneli acan herkese gecerli bir yonetici adresi -
            yani kimlik ciftinin yarisini - vermis olurduk. */}
        {editingEmail && (
          <div className="field">
            <label htmlFor="email">E-posta</label>
            <input
              id="email"
              type="email"
              autoComplete="username"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              autoFocus
            />
          </div>
        )}

        <div className="field">
          <label htmlFor="password">Parola</label>
          <input
            id="password"
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            autoFocus={!editingEmail}
          />
        </div>

        <button type="submit" disabled={busy}>
          {busy ? 'Doğrulanıyor…' : 'Aç'}
        </button>

        {!editingEmail && (
          <button type="button" className="link alt-account" onClick={useDifferentAccount}>
            Başka hesapla gir
          </button>
        )}
      </form>
    </div>
  );
}
