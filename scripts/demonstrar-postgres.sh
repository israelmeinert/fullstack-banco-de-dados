#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
require_docker
mkdir -p "$ROOT_DIR/resultados"
compose up -d --wait --wait-timeout 120 postgres
compose exec -T postgres psql -X -v ON_ERROR_STOP=1 -U aula -d aula < "$ROOT_DIR/laboratorio/postgres/01-preparar.sql"
echo 'Plano antes do índice composto:'
compose exec -T postgres psql -X -v ON_ERROR_STOP=1 -U aula -d aula < "$ROOT_DIR/laboratorio/postgres/02-antes.sql" | tee "$ROOT_DIR/resultados/postgres-antes.txt"
echo 'Plano depois do índice composto:'
compose exec -T postgres psql -X -v ON_ERROR_STOP=1 -U aula -d aula < "$ROOT_DIR/laboratorio/postgres/03-depois.sql" | tee "$ROOT_DIR/resultados/postgres-depois.txt"
