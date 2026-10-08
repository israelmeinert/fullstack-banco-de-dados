#!/usr/bin/env bash

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

compose() {
  docker compose --project-directory "$ROOT_DIR" -f "$ROOT_DIR/docker-compose.yml" "$@"
}

require_docker() {
  command -v docker > /dev/null || { echo 'Docker não encontrado.' >&2; exit 1; }
  docker compose version > /dev/null
  docker info > /dev/null
}

service_for() {
  case "$1" in
    postgres|vetorial) echo postgres ;;
    mongodb|redis|cassandra|neo4j|influxdb|clickhouse|elasticsearch) echo "$1" ;;
    sqlite) ;;
    *) echo "Tecnologia desconhecida: $1" >&2; return 1 ;;
  esac
}
