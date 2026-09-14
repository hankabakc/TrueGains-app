import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './styles.css';

// Masaustune "uygulama olarak yukle" secenegi icin gerekli. Service worker
// onbellek tutmuyor; tek isi paneli kurulabilir kilmak.
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js').catch(() => {
      // Kurulamamasi paneli engellemez; sessizce gecilir.
    });
  });
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
