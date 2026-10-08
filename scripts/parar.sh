#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
require_docker
[[ $# -eq 0 ]] || { echo 'Uso: ./scripts/parar.sh (preserva os volumes)' >&2; exit 2; }
compose --profile todos --profile ferramentas down
