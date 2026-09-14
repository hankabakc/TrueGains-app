/// <reference types="vitest/config" />
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Geliştirmede /api istekleri backend'e vekillenir.
//
// Origin başlığı BİLEREK siliniyor: vekil onu olduğu gibi iletirse Spring isteği
// "http://localhost:5174'ten gelen çapraz köken çağrısı" sayar ve CORS listesinde
// olmadığı için 403 döner. Başlık kalkınca istek aynı kökenli görünür ve backend'in
// CORS listesini geliştirme için genişletmek gerekmez — o liste üretimde dar kalmalı.
//
// Not: panel ayrıca nginx üzerinden http://admin.localhost:8082 adresinden de
// servis ediliyor (aynı köken, geliştirme sunucusuna bağımlı değil). Bu vekil
// yalnızca `npm run dev` ile çalışırken devrede.
export default defineConfig({
  server: {
    port: 5174,
    proxy: {
      '/api': {
        target: 'http://localhost:8082',
        changeOrigin: true,
        configure: (proxy) => {
          // Vite'ın `configure` imzası http-proxy olay yayıcısını tiplemiyor;
          // olay adı ve geri çağrı doğru, eksik olan yalnızca tür bilgisi.
          const emitter = proxy as unknown as {
            on(event: string, cb: (req: { removeHeader(name: string): void }) => void): void;
          };
          emitter.on('proxyReq', (proxyReq) => {
            proxyReq.removeHeader('origin');
            proxyReq.removeHeader('referer');
          });
        },
      },
    },
  },
  plugins: [react()],
  test: {
    // Genel ortam node kalır; DOM yalnızca bileşen testinde (@vitest-environment jsdom) açılır.
    // Böylece mevcut saf fonksiyon testleri jsdom yüküyle yavaşlamaz.
    environment: 'node',
    include: ['src/**/*.test.{ts,tsx}'],
  },
});
