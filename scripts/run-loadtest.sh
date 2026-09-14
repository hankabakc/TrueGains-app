#!/usr/bin/env sh
#
# Yük testi koşturucu.
#
# Kullanım:
#   sh scripts/run-loadtest.sh <email> <sifre>
#
# Ne yapar: verilen hesapla giriş yapar, aldığı token'la k6 senaryosunu compose ağının
# içinden çalıştırır. k6 konteyner olarak koşar, kurulum gerektirmez.
#
# Ön koşul: yığın ayakta (`docker compose -f backend/gym-v2/docker-compose.yml up -d`).
#
# NOT: Test backend'e doğrudan gider, vekili atlar. Gerekçe senaryo dosyasının başında —
# özetle, vekil üzerinden gidilseydi tüm yük tek IP sayılıp hız sınırına takılırdı ve
# ölçülen şey uygulama kapasitesi değil sınırlayıcı olurdu.

set -eu

EMAIL="${1:-}"
PASSWORD="${2:-}"
COMPOSE_DIR="${COMPOSE_DIR:-backend/gym-v2}"
NETWORK="${LOADTEST_NETWORK:-gym-v2_default}"
API="${API_URL:-http://localhost:8082}"

if [ -z "$EMAIL" ] || [ -z "$PASSWORD" ]; then
	echo "Kullanım: sh scripts/run-loadtest.sh <email> <sifre>" >&2
	exit 1
fi

echo "Giriş yapılıyor: $EMAIL"
TOKEN=$(curl -s -X POST "$API/api/v1/auth/login" \
	-H "Content-Type: application/json" \
	-d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"deviceId\":\"loadtest\"}" |
	python -c "import sys,json; print((json.load(sys.stdin).get('data') or {}).get('access_token',''))")

if [ -z "$TOKEN" ]; then
	echo "HATA: giriş başarısız, token alınamadı." >&2
	exit 1
fi

echo "Token alındı. k6 başlatılıyor (compose ağı: $NETWORK)"

# MSYS_NO_PATHCONV: Git Bash konteyner içi mutlak yolları Windows yoluna çeviriyor
# (`/scripts` → `C:/Program Files/Git/scripts`) ve docker "geçersiz yol" diyor. Linux'ta
# bu değişkenin hükmü yok, zararsız.
MSYS_NO_PATHCONV=1 docker run --rm -i \
	--network "$NETWORK" \
	-e "TOKEN=$TOKEN" \
	-e "BASE=http://backend:8082" \
	-e "PEAK=${PEAK:-60}" \
	-v "$(pwd)/scripts/loadtest:/scripts:ro" \
	-w /scripts \
	grafana/k6:0.55.0 run smoke.js
