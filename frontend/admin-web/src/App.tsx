import { useCallback, useEffect, useState } from 'react';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import Layout from './components/Layout';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import UsersPage from './pages/UsersPage';
import ReportsPage from './pages/ReportsPage';
import FinancePage from './pages/FinancePage';
import ErrorsPage from './pages/ErrorsPage';
import AuditPage from './pages/AuditPage';
import { setUnauthorizedHandler, tokenStore, userStore } from './api/client';
import type { AuthUser } from './api/types';

export default function App() {
  // Yenilemede oturum korunur: jeton ve kullanıcı birlikte varsa panel açılır. Jeton
  // geçersizse ilk istek 401/403 alır ve onUnauthorized çıkış yapar.
  const [user, setUser] = useState<AuthUser | null>(() => (tokenStore.get() ? userStore.get() : null));

  const signOut = useCallback(() => {
    tokenStore.clear();
    setUser(null);
  }, []);

  // Jeton dustugunde her sayfanin ayri ayri ele almasi gerekmesin: istemci
  // katmani tek yerden haber veriyor.
  useEffect(() => {
    setUnauthorizedHandler(signOut);
  }, [signOut]);

  if (!user) {
    return <LoginPage onSignedIn={setUser} />;
  }

  return (
    <BrowserRouter>
      <Routes>
        <Route element={<Layout user={user} onSignOut={signOut} />}>
          <Route index element={<DashboardPage />} />
          <Route path="users" element={<UsersPage />} />
          <Route path="reports" element={<ReportsPage />} />
          <Route path="finance" element={<FinancePage />} />
          <Route path="errors" element={<ErrorsPage />} />
          <Route path="audit" element={<AuditPage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
