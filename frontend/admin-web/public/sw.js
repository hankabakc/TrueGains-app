// Kurulabilirlik icin gereken en kucuk service worker.
//
// ONBELLEK YOK ve bilerek yok: bu bir yonetim araci, gosterdigi sayilarin
// bayat olmasi kabul edilemez. Istekler dokunulmadan aga gidiyor.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));
