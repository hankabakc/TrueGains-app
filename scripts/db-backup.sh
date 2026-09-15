#!/usr/bin/env sh
#
# Veritabanı yedeği alır.
#
# Flyway'in ücretsiz sürümünde undo yok: bozuk bir migration'ın tek geri dönüşü yedekten
# dönmektir. Yedek yoksa geri dönüş de yok.
#
# Kullanım (host'ta, depo kökünde; veritabanı konteynerine docker exec ile bağlanır):
#   sh scripts/db-backup.sh
#
# Otomatik günlük yedek: docker-compose.yml'deki `db-backup` servisi bu betiği her gün
# 03:00'te (Europe/Istanbul) koşar. Orada PGHOST tanımlı olduğu için betik docker exec
# yerine ağdan bağlanır.
#
# Ayarlar ortam değişkeniyle geçilebilir: DB_CONTAINER, PGHOST, PGPASSWORD, PGDATABASE,
# PGUSER, BACKUP_DIR, BACKUP_KEEP_DAYS.
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
if [ -n "${PGHOST:-}" ]; then
	# Ağ kipi (docker-compose.yml → db-backup): pg_dump PGHOST ve PGPASSWORD'u ortamdan okur.
	pg_dump -U "$DB_USER" -d "$DB_NAME" | gzip >"$FILE"
else
	docker exec "$CONTAINER" pg_dump -U "$DB_USER" -d "$DB_NAME" | gzip >"$FILE"
fi

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

# Boru hattında pg_dump'ın çıkış kodu kaybolur, yalnızca gzip'inki görünür: parola ya da
# bağlantı hatasında boş girdinin gzip'i ~20 baytlık, `gzip -t`'den geçen bir dosya olur.
# pg_dump başarıyla biten her düz yedeğin sonuna bu satırı yazar; yoksa yedek eksiktir.
if ! gunzip -c "$FILE" | tail -n 10 | grep -q 'PostgreSQL database dump complete'; then
	echo "HATA: yedek eksik (pg_dump tamamlanmadı), siliniyor: $FILE" >&2
	rm -f "$FILE"
	exit 1
fi

SIZE=$(wc -c <"$FILE" | tr -d ' ')
echo "Yedek alındı: $FILE (${SIZE} bayt)"

# Saklama süresi: eski yedekler temizlenir, yoksa disk dolar.
DELETED=$(find "$OUT_DIR" -name "${DB_NAME}-*.sql.gz" -type f -mtime "+${KEEP_DAYS}" -print -delete | wc -l | tr -d ' ')
echo "Saklama: ${KEEP_DAYS} gün · silinen eski yedek: ${DELETED}"
