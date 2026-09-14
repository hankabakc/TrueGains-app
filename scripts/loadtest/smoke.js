// GymApp-V2 yük testi — gerçekçi okuma karışımı.
//
// ÇALIŞTIRMA (scripts/run-loadtest.sh üzerinden çağrılır):
//   k6 run -e TOKEN=<jwt> -e BASE=http://backend:8082 smoke.js
//
// NEDEN VEKİLİ ATLIYOR: test compose ağının içinden doğrudan backend'e gidiyor. Amaç
// uygulamanın kapasitesini ölçmek; vekil üzerinden gidilseydi tüm yük tek IP'den gelmiş
// gibi görünüp dakikada 100 istekte hız sınırına takılırdı ve ölçülen şey uygulama değil
// sınırlayıcı olurdu. Her sanal kullanıcı kendi X-Forwarded-For'unu gönderiyor, yani
// backend onları ayrı istemci sayıyor.
//
// NE ÖLÇMÜYOR: nginx'in kendi gecikmesi ve TLS maliyeti bu ölçümün dışında.

import http from "k6/http";
import { check, sleep } from "k6";
import { Trend } from "k6/metrics";

const BASE = __ENV.BASE || "http://backend:8082";
const TOKEN = __ENV.TOKEN;

const dashboardTrend = new Trend("ekran_panel", true);
const chatTrend = new Trend("ekran_sohbet", true);
const dietTrend = new Trend("ekran_diyet", true);

// Tepe eşzamanlı kullanıcı. Varsayılan 60 "normal gün" ölçümü; kırılma noktası aramak
// için `-e PEAK=400` gibi yükseltilir.
const PEAK = parseInt(__ENV.PEAK || "60", 10);

export const options = {
  // Kademeli yük: kırılma noktası tek bir sayıyla değil, eğrinin nerede bozulduğuyla
  // anlaşılır.
  stages: [
    { duration: "20s", target: Math.max(1, Math.round(PEAK / 6)) },
    { duration: "30s", target: Math.max(1, Math.round(PEAK / 2)) },
    { duration: "30s", target: PEAK },
    { duration: "20s", target: 0 },
  ],
  thresholds: {
    // Mobil uygulamada 500 ms üstü ekran açılışı fark edilir hale gelir.
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<500"],
  },
};

function get(path, trend) {
  const res = http.get(`${BASE}${path}`, {
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      // Her YİNELEME ayrı bir kullanıcı oturumu gibi görünsün.
      //
      // Önce yalnızca __VU kullanılıyordu ve sanal kullanıcı başına saniyede 5 istek
      // (dakikada 300) düşüyordu; genel kova 100/dk olduğu için isteklerin %27'si 429
      // aldı. Ölçülen şey uygulama kapasitesi değil hız sınırlayıcısı oluyordu.
      // Yineleme numarası eklenince her tur taze bir istemci sayılıyor ve tur başına
      // 5 istek sınırın çok altında kalıyor.
      "X-Forwarded-For": `10.${__VU % 250}.${__ITER % 250}.${(__VU * 7 + __ITER) % 250}`,
    },
    tags: { name: path },
  });
  check(res, { [`${path} 200`]: (r) => r.status === 200 });
  if (trend) trend.add(res.timings.duration);
  return res;
}

export default function () {
  // Sporcunun tipik oturumu: panel → diyet → ölçüm → sohbet.
  get("/api/v1/nutrition/analytics/dashboard", dashboardTrend);
  get("/api/v1/nutrition/diet/my-programs", dietTrend);
  get("/api/v1/measurements/today", null);
  get("/api/v1/social/chat/conversations", chatTrend);
  get("/api/v1/finance/my-subscription", null);

  // Kullanıcı ekranlar arasında düşünüyor; sıfır bekleme gerçekçi değil ve yalnızca
  // sunucuyu yapay olarak boğar.
  sleep(1);
}
