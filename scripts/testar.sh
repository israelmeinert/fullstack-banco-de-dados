#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
require_docker
mkdir -p "$ROOT_DIR/resultados"
exec > >(tee "$ROOT_DIR/resultados/testes-${1:-basico}.log") 2>&1

case "${1:-basico}" in
  basico) grupos=(postgres mongodb redis vetorial sqlite) ;;
  opcionais) grupos=(cassandra neo4j influxdb clickhouse elasticsearch) ;;
  todos) grupos=(postgres mongodb redis vetorial sqlite cassandra neo4j influxdb clickhouse elasticsearch) ;;
  *) service_for "$1" > /dev/null; grupos=("$1") ;;
esac

compose --profile ferramentas build testes
CURRENT_SERVICE=''
STOP_CURRENT=0
cleanup() {
  if [[ "$STOP_CURRENT" == 1 && -n "$CURRENT_SERVICE" ]]; then
    compose --profile todos stop "$CURRENT_SERVICE"
  fi
}
trap cleanup EXIT
trap 'echo "FALHOU: ${grupo:-preparação}. Confira o log em resultados/." >&2' ERR
trap 'exit 130' INT
trap 'exit 143' TERM

runner() {
  compose run --rm --no-deps --user "$(id -u):$(id -g)" testes "$1"
}

backup_postgres() {
  local restore_db assinatura restaurada
  restore_db="aula_restore_$(date +%s)_$$"
  compose exec -T postgres pg_dump -U aula -d aula -n aula_db -Fc > "$ROOT_DIR/resultados/aula_db.dump"
  compose exec -T postgres createdb -U aula "$restore_db"
  # A extensão já existe caso o teste vetorial tenha sido executado antes.
  if ! compose exec -T postgres psql -X -v ON_ERROR_STOP=1 -U aula -d "$restore_db" -c 'CREATE EXTENSION IF NOT EXISTS vector' > /dev/null ||
     ! compose exec -T postgres pg_restore -U aula -d "$restore_db" --exit-on-error < "$ROOT_DIR/resultados/aula_db.dump"; then
    compose exec -T postgres dropdb -U aula "$restore_db"
    return 1
  fi
  local sql="SELECT count(*), md5(string_agg(concat_ws(':',id,cliente_id,extract(epoch FROM criado_em),total_centavos), ',' ORDER BY id)) FROM aula_db.pedidos_demo"
  assinatura="$(compose exec -T postgres psql -X -U aula -d aula -Atc "$sql")"
  restaurada="$(compose exec -T postgres psql -X -U aula -d "$restore_db" -Atc "$sql")"
  compose exec -T postgres dropdb -U aula "$restore_db"
  [[ "$assinatura" == "$restaurada" && "$assinatura" == 200000\|* ]] || return 1
  echo 'PASS: backup restaurado em outra base; contagem e hash dos pedidos conferem.'
}

testar_redis() {
  local valor ttl expirado ranking politica
  compose exec -T redis redis-cli SET aula:produto:42:resumo '{"nome":"Mochila"}' EX 60 > /dev/null
  valor="$(compose exec -T redis redis-cli --raw GET aula:produto:42:resumo)"
  ttl="$(compose exec -T redis redis-cli --raw TTL aula:produto:42:resumo)"
  [[ "$valor" == '{"nome":"Mochila"}' && "$ttl" -gt 0 && "$ttl" -le 60 ]]
  compose exec -T redis redis-cli SET aula:expiracao teste PX 100 > /dev/null
  sleep 0.3
  expirado="$(compose exec -T redis redis-cli --raw EXISTS aula:expiracao)"
  [[ "$expirado" == 0 ]]
  compose exec -T redis redis-cli DEL aula:ranking > /dev/null
  compose exec -T redis redis-cli ZADD aula:ranking 10 produto:42 20 produto:7 > /dev/null
  ranking="$(compose exec -T redis redis-cli --raw ZREVRANGE aula:ranking 0 0)"
  [[ "$ranking" == produto:7 ]]
  politica="$(compose exec -T redis redis-cli --raw CONFIG GET maxmemory-policy)"
  [[ "$politica" == $'maxmemory-policy\nallkeys-lru' ]]
  echo 'PASS: Redis — leitura por chave, TTL, expiração, ranking e política de memória.'
}

testar_neo4j() {
  local saida
  # shellcheck disable=SC2016 # As variáveis pertencem ao ambiente do container.
  saida="$(compose exec -T neo4j sh -c 'exec cypher-shell -u neo4j -p "${NEO4J_AUTH#*/}" --format plain -f /scripts/testes.cypher')"
  echo "$saida"
  [[ "$saida" == $'cliente_relacionado\n7' ]] || {
    echo 'O grafo deveria retornar somente o cliente 7.' >&2; return 1;
  }
  echo 'PASS: Neo4j — a travessia encontra somente o cliente que compartilha o dispositivo.'
}

for grupo in "${grupos[@]}"; do
  echo "Executando: $grupo"
  CURRENT_SERVICE="$(service_for "$grupo")"
  STOP_CURRENT=0
  if [[ -n "$CURRENT_SERVICE" ]]; then
    running="$(compose --profile todos ps --status running -q "$CURRENT_SERVICE")"
    [[ -n "$running" ]] || STOP_CURRENT=1
    compose --profile todos up -d --wait --wait-timeout 480 "$CURRENT_SERVICE"
  fi
  case "$grupo" in
    postgres) runner postgres; backup_postgres ;;
    vetorial|sqlite|influxdb|elasticsearch) runner "$grupo" ;;
    mongodb) compose exec -T mongodb mongosh --quiet --file /dev/stdin < "$ROOT_DIR/laboratorio/mongodb/testes.js" ;;
    redis) testar_redis ;;
    cassandra)
      saida="$(compose exec -T cassandra cqlsh --request-timeout=120 -f /scripts/testes.cql)"
      echo "$saida"
      [[ "$saida" == *entregue* && "$saida" == *coletado* && "$saida" != *outra_transportadora* ]]
      echo 'PASS: Cassandra — consulta recupera apenas a partição da transportadora e do dia.' ;;
    neo4j) testar_neo4j ;;
    clickhouse)
      # shellcheck disable=SC2016 # As variáveis pertencem ao ambiente do container.
      compose exec -T clickhouse sh -c 'exec clickhouse-client --user "$CLICKHOUSE_USER" --password "$CLICKHOUSE_PASSWORD" --multiquery' < "$ROOT_DIR/laboratorio/clickhouse/testes.sql"
      echo 'PASS: ClickHouse — filtro por data e soma por categoria.' ;;
  esac
  cleanup
  STOP_CURRENT=0
  echo "PASS: $grupo"
done
echo "Testes concluídos. Relatórios em $ROOT_DIR/resultados"
