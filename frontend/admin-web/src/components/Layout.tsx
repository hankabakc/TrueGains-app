import { NavLink, Outlet } from 'react-router-dom';
import type { AuthUser } from '../api/types';

const NAV = [
  { to: '/', label: 'Panel', end: true },
  { to: '/users', label: 'Kullanıcılar' },
  { to: '/reports', label: 'Şikâyetler' },
  { to: '/finance', label: 'Gelir' },
  { to: '/errors', label: 'Hatalar' },
  { to: '/audit', label: 'Denetim' },
];

export default function Layout({ user, onSignOut }: { user: AuthUser; onSignOut: () => void }) {
  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">GymApp Yönetim</div>
        <nav>
          {NAV.map((item) => (
            <NavLink key={item.to} to={item.to} end={item.end} className={({ isActive }) => (isActive ? 'active' : '')}>
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="sidebar-foot">
          <div className="muted who">{user.email}</div>
          <button className="ghost" onClick={onSignOut}>
            Çıkış
          </button>
        </div>
      </aside>
      <main>
        <Outlet />
      </main>
    </div>
  );
}
