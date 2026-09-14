#!/usr/bin/env sh
#
# Veritabanı yedeği alır.
#
# Flyway'in ücretsiz sürümünde undo yok: bozuk bir migration'ın tek geri dönüşü yedekten
# dönmektir. Yedek yoksa geri dönüş de yok.
#
# Kullanım:
#   sh scripts/db-backup.sh
#
# Sunucuda günlük cron (03:00):
#   0 3 * * * cd /opt/gymapp && sh scripts/db-backup.sh >> /var/log/gymapp-backup.log 2>&1
#
# Ayarlar ortam değişkeniyle geçilebilir: DB_CONTAINER, PGDATABASE, PGUSER, BACKUP_DIR,
# BACKUP_KEEP_DAYS.
#
# NOT: Yedek almak yetmez — geri yüklenebildiği kanıtlanmalı. `db-restore-drill.sh`
# bunun için var; denenmemiş yedek yedek sayılmaz.

set -eu

CONTAINER="${DB_CONTAINER:-gymapp_v2_db}"
DB_NAME="${PGDATABASE:-gymapp_v2}"
DB_USER="${PGUSER:-gymapp_admin}"
OUT_DIR="${BACKUP_DIR:-backups}"
KEEP_DAYS="${BACKUP_KEEP_DAYS:-14}"

mkdir -p "$OUT_DIR"

STAMP=$(date +%Y%m%d-%H%M%S)
FILE="$OUT_DIR/${DB_NAME}-${STAMP}.sql.gz"

# Düz SQL + gzip; özel biçim (-Fc) yerine tercih edildi çünkü tek dosya, gözle
# okunabilir ve pg_restore sürüm uyumu derdi çıkarmıyor.
docker exec "$CONTAINER" pg_dump -U "$DB_USER" -d "$DB_NAME" | gzip >"$FILE"

# Sessiz başarısızlık en tehlikelisi: boş ya da bozuk dosya "yedek var" sanılır.
if [ ! -s "$FILE" ]; then
	echo "HATA: yedek boş çıktı, siliniyor: $FILE" >&2
	rm -f "$FILE"
	exit 1
fi

if ! gzip -t "$FILE" 2>/dev/null; then
	echo "HATA: yedek bozuk (gzip doğrulaması başarısız): $FILE" >&2
	exit 1
fi

SIZE=$(wc -c <"$FILE" | tr -d ' ')
echo "Yedek alındı: $FILE (${SIZE} bayt)"

# Saklama süresi: eski yedekler temizlenir, yoksa disk dolar.
DELETED=$(find "$OUT_DIR" -name "${DB_NAME}-*.sql.gz" -type f -mtime "+${KEEP_DAYS}" -print -delete | wc -l | tr -d ' ')
echo "Saklama: ${KEEP_DAYS} gün · silinen eski yedek: ${DELETED}"
