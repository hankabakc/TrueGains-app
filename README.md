# 🏋️ TrueGains
### Antrenör–Danışan Eşleştirme, Beslenme, Antrenman ve Gelişim Takip Platformu

[![Java](https://img.shields.io/badge/Java-25_(Virtual_Threads)-orange?style=for-the-badge&logo=openjdk)](https://openjdk.org/)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot-4.0.3-6DB33F?style=for-the-badge&logo=springboot)](https://spring.io/projects/spring-boot)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-336791?style=for-the-badge&logo=postgresql)](https://www.postgresql.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.47_(BLoC)-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev/)
[![React](https://img.shields.io/badge/React-19.2_(Admin)-61DAFB?style=for-the-badge&logo=react)](https://react.dev/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker)](https://www.docker.com/)

---

## 🌐 İçindekiler / Table of Contents
- [🇹🇷 Türkçe](#-türkçe)
  - [Genel Bakış](#-genel-bakış)
  - [Depo Yapısı](#-depo-yapısı)
  - [Temel Modüller](#-temel-modüller)
  - [Mimari ve Güvenlik](#️-mimari-ve-güvenlik)
  - [Hızlı Kurulum (Yerel Geliştirme)](#-hızlı-kurulum-yerel-geliştirme)
  - [İzleme ve İşletim](#-izleme-ve-işletim)
  - [Yedekleme ve Geri Yükleme Provası](#-yedekleme-ve-geri-yükleme-provası)
  - [Testlerin Çalıştırılması](#-testlerin-çalıştırılması)
- [🇺🇸 English (Summary)](#-english-summary)

---

## 🇹🇷 Türkçe

### 📝 Genel Bakış
**TrueGains**, antrenörlerin (koç) danışanlarıyla eşleştiği; beslenme, antrenman programı, vücut ölçümü ve abonelik süreçlerinin tek yerden yürütüldüğü bir mobil fitness platformudur.

- **Mobil uygulama (Flutter):** danışan ve koçun kullandığı ana istemci.
- **Yönetim paneli (React):** kullanıcı, moderasyon, finans, denetim kaydı ve hata özeti için web paneli.
- **Backend (Spring Boot):** tüm iş kurallarının yaşadığı modüler monolit.

---

### 🗂️ Depo Yapısı

```text
.
├── backend/gym-v2/          → Spring Boot API, Flyway migrasyonları, Docker Compose yığını, nginx, izleme ayarları
├── frontend/gymapp-v2/      → Flutter mobil uygulama (BLoC + GoRouter)
├── frontend/admin-web/      → React + Vite yönetim paneli
├── scripts/                 → Veritabanı yedeği, geri yükleme provası, k6 yük testi
└── .github/workflows/ci.yml → Backend + Flutter kalite kapısı
```

---

### ✨ Temel Modüller

| Modül | Açıklama |
| :--- | :--- |
| **`auth`** | JWT erişim token'ı + refresh token, OTP doğrulama (SMS gönderimi şu an **simülasyon**), kullanıcı hesabı işlemleri. |
| **`membership`** | Kullanıcı profili. |
| **`social`** | Koç profilleri (pazaryeri), koç–danışan eşleştirme ve danışan talepleri, STOMP/WebSocket üzerinden anlık sohbet, danışan galerisi, gelişim görünümü, kullanıcı şikâyetleri. |
| **`training`** | Antrenman programları ve danışana program atama. |
| **`nutrition`** | Diyet planları, besin veritabanı, öğün kaydı ve şablonları, tarifler, su takibi, beslenme analitiği. Fotoğraftan besin okuma (OCR) ve öneriler **Gemini** ile yapılır; hesap başına günlük kota uygulanır. |
| **`measurement`** | Vücut ölçümleri; koçun danışan ölçümlerini görmesi. |
| **`finance`** | Abonelik paketleri, sipariş, ödeme akışı, webhook ve abonelik bitiş zamanlayıcısı. Ödeme sağlayıcısı `PaymentGatewayService` arayüzünün arkasındadır; bugün **sahte (mock) sağlayıcı** ile çalışır, gerçek sağlayıcı adaptör olarak eklenecektir. |
| **`admin`** | Genel bakış, kullanıcı yönetimi, moderasyon, finans, denetim kaydı, Sentry hata özeti, sistem durumu. |
| **`core`** | Dosya yükleme, istemci sürüm kilidi, PII şifreleme, HTML temizleme, hız sınırlama, denetim izi, Sentry. |

---

### 🛡️ Mimari ve Güvenlik

* **Modüler monolit:** her iş alanı kendi paketinde (`controller` / `service` / `repository` / `dto` / `entity`). DTO dönüşümleri **MapStruct** ile yapılır.
* **Java 25 Virtual Threads:** bloklayıcı veritabanı ve dış servis çağrıları reaktif programlamaya geçmeden eşzamanlı yürütülür.
* **Şema yalnızca migrasyonla değişir:** Flyway (`V1`–`V100`), `ddl-auto=validate`.
* **PII şifreleme:** kişisel veri alanları veritabanında **AES-256-GCM** ile şifreli saklanır.
* **Sır yok:** API anahtarı, parola ve imza anahtarları kaynakta tutulmaz; hepsi ortam değişkeninden okunur (`.env.example` şablon olarak depodadır). İlk yönetici hesabı da ortam değişkeniyle, yalnızca veritabanında hiç yönetici yokken bir kez açılır.
* **Tek giriş noktası:** dış dünyaya yalnızca nginx vekili açılır (`8082`). Backend doğrudan yayınlanmaz; böylece `X-Forwarded-For` sahteciliğiyle hız sınırı atlatılamaz.
* **Hız sınırlama:** Bucket4j tabanlı; WAF filtresi etkin.
* **İşletim uçları ayrı portta:** Actuator (`health`, `prometheus`) yalnızca iç ağdaki `9090` portundadır, ayrıntı dışarı verilmez.
* **CORS:** joker (`*`) kabul edilmez; izinli adresler ortamdan verilir.
* **İstemci sürüm kilidi:** API sözleşmesini bozan dağıtımlarda asgari mobil sürüm sunucudan yükseltilir.

---

### 🔧 Hızlı Kurulum (Yerel Geliştirme)

#### Gereksinimler
- **Java 25 SDK** (Eclipse Temurin önerilir)
- **Flutter 3.47** (stable)
- **Node.js 22 LTS** & **npm** (yönetim paneli için)
- **Docker** & **Docker Compose**

#### 1. Depoyu klonlayın
```bash
git clone https://github.com/hankabakc/TrueGains-app.git
cd TrueGains-app
```

#### 2. Ortam değişkenlerini hazırlayın
```bash
cp backend/gym-v2/.env.example backend/gym-v2/.env
cp frontend/gymapp-v2/.env.example frontend/gymapp-v2/.env
```
`backend/gym-v2/.env` içinde en az `DB_PASSWORD`, `JWT_SECRET`, `ENCRYPTION_KEY` ve `GRAFANA_PASSWORD` doldurulmalıdır (`GRAFANA_PASSWORD` yoksa compose başlamaz).

> Firebase kimlik dosyaları (`google-services.json`, `GoogleService-Info.plist`, `firebase-adminsdk*.json`) depoda **yoktur**; kendi Firebase projenizden alınmalıdır.

#### 3. Yönetim panelini derleyin
nginx paneli `frontend/admin-web/dist` klasöründen servis eder:
```bash
cd frontend/admin-web
npm install
npm run build
cd ../..
```

#### 4. Yığını başlatın (PostgreSQL 17 · Backend · nginx · izleme)
```bash
cd backend/gym-v2
docker compose up -d --build
```

| Servis | Adres |
| :--- | :--- |
| API (nginx vekili) | `http://localhost:8082` |
| Yönetim paneli | `http://admin.localhost:8082` |
| PostgreSQL | `localhost:5434` |
| Grafana | `http://127.0.0.1:3001` |
| Prometheus | `http://127.0.0.1:9091` |

Panel geliştirilirken `npm run dev` ile `http://localhost:5174` üzerinden de açılabilir; `/api` istekleri backend'e vekillenir.

#### 5. Mobil uygulamayı çalıştırın
```bash
cd frontend/gymapp-v2
flutter pub get
flutter run --dart-define-from-file=.env
```
`API_HOST` verilmezse Android emülatöründen host makineye çıkan `10.0.2.2` kullanılır. Aynı ağdaki gerçek cihaz için bilgisayarın yerel IP'si yazılır.

---

### 📈 İzleme ve İşletim

* **Metrik:** Prometheus + postgres-exporter → Grafana
* **Log:** Promtail → Loki → Grafana. Tüm konteynerlerde log döndürme açıktır (10 MB × 3 dosya).
* **Hata izleme:** Sentry (backend ve mobil). Sentry okuma jetonu sunucuda kalır, tarayıcıya inmez.
* **Yük testi:** k6, compose ağının içinden koşar, kurulum gerektirmez:
  ```bash
  sh scripts/run-loadtest.sh <email> <sifre>
  ```

---

### 📦 Yedekleme ve Geri Yükleme Provası

```bash
# Veritabanı yedeği (sunucuda günlük cron ile çalıştırılması önerilir)
sh scripts/db-backup.sh

# Geri yükleme provası: en son yedeği AYRI bir kontrol veritabanına yükler,
# kaynakla karşılaştırır ve kontrol veritabanını siler. Gerçek veritabanına dokunmaz.
sh scripts/db-restore-drill.sh
```

Yedekler `backups/` klasörüne yazılır ve depoya girmez.

---

### 🧪 Testlerin Çalıştırılması

```bash
# Backend: birim + entegrasyon testleri (Testcontainers, Docker gerekir), stil denetimi
cd backend/gym-v2
./mvnw test
./mvnw checkstyle:check

# Mobil: statik analiz + testler
cd ../../frontend/gymapp-v2
flutter analyze
flutter test

# Yönetim paneli: testler + tip denetimi
cd ../admin-web
npm test
npm run build
```

Her push'ta GitHub Actions backend testlerini, Checkstyle'ı, `flutter analyze` ve `flutter test` adımlarını koşturur.

---

## 🇺🇸 English (Summary)

**TrueGains** is a mobile fitness platform that connects coaches with clients and manages nutrition, training programs, body measurements and subscriptions in one place.

### Key Highlights
- **Three clients, one backend:** Flutter mobile app (BLoC), React admin panel, and a **Java 25 / Spring Boot 4** modular monolith on **PostgreSQL 17** (Flyway).
- **Coach marketplace & real-time chat:** coach profiles, client pairing, and STOMP/WebSocket messaging.
- **Nutrition with AI assist:** meal logging, diet plans and recipes; photo-based food recognition via Gemini with a per-account daily quota.
- **Security by default:** AES-256-GCM field-level PII encryption, JWT with refresh tokens, rate limiting, single reverse-proxy entry point, zero secrets in source.
- **Operations included:** Docker Compose stack with nginx, Prometheus, Grafana, Loki, backup and restore-drill scripts, and a k6 load test.
