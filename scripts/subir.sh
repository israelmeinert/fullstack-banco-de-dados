#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
require_docker

case "${1:-basico}" in
  basico) services=(postgres mongodb redis) ;;
  todos) services=(postgres mongodb redis cassandra neo4j influxdb clickhouse elasticsearch) ;;
  *) service="$(service_for "$1")"; services=(); [[ -z "$service" ]] || services+=("$service") ;;
esac
if ((${#services[@]})); then
  compose --profile todos up -d --wait --wait-timeout 480 "${services[@]}"
fi
