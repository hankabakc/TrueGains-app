#!/usr/bin/env sh
#
# Geri yükleme provası: en son yedeği **ayrı bir kontrol veritabanına** geri yükler,
# içeriğini kaynakla karşılaştırır, sonra kontrol veritabanını siler.
#
# Neden ayrı bir veritabanı: prova, yedeğin gerçekten geri yüklenebildiğini kanıtlamak
# içindir. Gerçek veritabanının üstüne yazmak bunun için gerekli değil ve felaket riski
# taşır. Script gerçek veritabanına **dokunmaz** ve hedef adı gerçek adla aynıysa durur.
#
# Kullanım:
#   sh scripts/db-restore-drill.sh              # en yeni yedekle
#   sh scripts/db-restore-drill.sh backups/x.gz # belirli bir yedekle
#
# GERÇEK FELAKET GERİ DÖNÜŞÜ BU SCRIPT DEĞİLDİR. Üretimde geri dönmek gerekirse:
#   1. Uygulamayı durdur (bağlantılar kesilsin)
#   2. gunzip -c <yedek> | docker exec -i <konteyner> psql -U <kullanıcı> -d postgres
#      (dump kendi CREATE/DROP komutlarını taşımıyorsa hedef veritabanını önce elle
#       hazırla — bu adım bilinçli olarak otomatikleştirilmedi)
#   3. Uygulamayı başlat, `flyway_schema_history` son sürümünü doğrula

set -eu

CONTAINER="${DB_CONTAINER:-gymapp_v2_db}"
DB_NAME="${PGDATABASE:-gymapp_v2}"
DB_USER="${PGUSER:-gymapp_admin}"
OUT_DIR="${BACKUP_DIR:-backups}"
SCRATCH="${SCRATCH_DB:-gymapp_v2_restore_check}"

# Güvenlik kilidi: prova hiçbir koşulda gerçek veritabanına yazmaz.
if [ "$SCRATCH" = "$DB_NAME" ]; then
	echo "HATA: kontrol veritabanı gerçek veritabanıyla aynı olamaz ($SCRATCH)" >&2
	exit 1
fi

FILE="${1:-}"
if [ -z "$FILE" ]; then
	FILE=$(ls -1t "$OUT_DIR"/${DB_NAME}-*.sql.gz 2>/dev/null | head -n 1 || true)
fi

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
	echo "HATA: geri yüklenecek yedek bulunamadı ($OUT_DIR)" >&2
	exit 1
fi

echo "Prova yedeği: $FILE"

psql_scratch() {
	docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$SCRATCH" -tAq -c "$1"
}

# Kontrol veritabanı her provada sıfırdan kurulur; kalıntı, provayı yalancı yeşile boyar.
docker exec "$CONTAINER" psql -U "$DB_USER" -d postgres -q -c "DROP DATABASE IF EXISTS $SCRATCH;"
docker exec "$CONTAINER" psql -U "$DB_USER" -d postgres -q -c "CREATE DATABASE $SCRATCH;"

# ON_ERROR_STOP olmadan psql hatayı yutup 0 döner ve prova yalancı yeşil olur.
if ! gunzip -c "$FILE" | docker exec -i "$CONTAINER" \
	psql -U "$DB_USER" -d "$SCRATCH" -q -v ON_ERROR_STOP=1 >/dev/null; then
	echo "HATA: geri yükleme başarısız — bu yedek kullanılamaz." >&2
	docker exec "$CONTAINER" psql -U "$DB_USER" -d postgres -q -c "DROP DATABASE IF EXISTS $SCRATCH;"
	exit 1
fi

# Doğrulama: yalnızca "hata vermedi" yetmez, içerik geldi mi bakılır.
TABLES=$(psql_scratch "SELECT count(*) FROM information_schema.tables WHERE table_schema='public';")
MIGRATIONS=$(psql_scratch "SELECT count(*) FROM flyway_schema_history;")
USERS=$(psql_scratch "SELECT count(*) FROM app_user;")

SRC_MIGRATIONS=$(docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -tAq \
	-c "SELECT count(*) FROM flyway_schema_history;")
SRC_USERS=$(docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -tAq \
	-c "SELECT count(*) FROM app_user;")

echo "Geri yüklenen: tablo=$TABLES migration=$MIGRATIONS kullanıcı=$USERS"
echo "Kaynak:                        migration=$SRC_MIGRATIONS kullanıcı=$SRC_USERS"

STATUS=0
if [ "$TABLES" -lt 1 ]; then
	echo "HATA: geri yüklenen veritabanında tablo yok." >&2
	STATUS=1
fi
if [ "$MIGRATIONS" != "$SRC_MIGRATIONS" ] || [ "$USERS" != "$SRC_USERS" ]; then
	echo "HATA: geri yüklenen içerik kaynakla uyuşmuyor." >&2
	STATUS=1
fi

docker exec "$CONTAINER" psql -U "$DB_USER" -d postgres -q -c "DROP DATABASE IF EXISTS $SCRATCH;"

if [ "$STATUS" -eq 0 ]; then
	echo "PROVA BAŞARILI — bu yedek geri yüklenebilir."
else
	echo "PROVA BAŞARISIZ." >&2
fi
exit "$STATUS"
