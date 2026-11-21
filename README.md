# TrueGains

Antrenörlerle danışanları buluşturan fitness uygulaması. Antrenör danışanına antrenman ve beslenme programı atar, ölçümlerini takip eder; iki taraf uygulama içinden mesajlaşır. Antrenörlük paketleri abonelik olarak satılır.

Depoda üç parça var:

```text
backend/gym-v2/        Spring Boot API (bütün iş kuralları burada)
frontend/gymapp-v2/    Flutter mobil uygulama (danışan ve antrenör)
frontend/admin-web/    React yönetim paneli
```

## Backend

Java, Spring Boot, Spring Data JPA, Spring Security, PostgreSQL, Flyway, WebSocket (STOMP), MapStruct.

Kod iş alanlarına göre paketlere ayrılmış, her pakette `controller / service / repository / dto / entity` katmanları var:

| Paket | İçerik |
| --- | --- |
| `auth` | Kayıt, giriş, access + refresh token, çıkışta token'ın kara listeye alınması |
| `social` | Antrenör profilleri, antrenör–danışan eşleşmesi, WebSocket ile mesajlaşma |
| `training` | Antrenman programları ve danışana atanması |
| `nutrition` | Diyet planları, öğün kaydı, besin veritabanı |
| `measurement` | Vücut ölçümleri |
| `finance` | Abonelik paketleri, sipariş ve ödeme akışı (ödeme sağlayıcısı şu an sahte/mock), süresi biten aboneliklerin kapatılması |
| `admin` | Yönetim paneli uçları |
| `core` | Güvenlik ayarları, hata yönetimi, istek sınırlama, dosya yükleme |

Veritabanı şeması yalnızca Flyway migrasyonlarıyla değişir (`ddl-auto=validate`). Gizli anahtarlar kodda değil, ortam değişkenlerindedir (`.env.example`).

## Çalıştırma

Gerekenler: JDK 25, Docker, Flutter, Node.js.

```bash
cd backend/gym-v2
cp .env.example .env        # DB_PASSWORD, JWT_SECRET, ENCRYPTION_KEY, GRAFANA_PASSWORD doldurulmalı
docker compose up -d --build
```

API `http://localhost:8082` adresinden açılır. Mobil uygulama:

```bash
cd frontend/gymapp-v2
cp .env.example .env
flutter pub get
flutter run --dart-define-from-file=.env
```

Firebase dosyaları depoda yok; bildirimler için kendi Firebase projenizin dosyaları gerekir.

## Testler

```bash
cd backend/gym-v2
./mvnw test
```

Birim testleri JUnit ve Mockito ile, entegrasyon testleri Testcontainers ile (Docker içinde gerçek PostgreSQL) yazıldı. GitHub Actions her push'ta backend testlerini ve Flutter analizini çalıştırır.
