#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"
require_docker
cd "$ROOT_DIR"

compose run --rm --no-deps marp aula-bancos-de-dados-marp.md -o index.html
compose run --rm --no-deps marp aula-bancos-de-dados-marp.md --pdf -o aula-bancos-de-dados.pdf

# A imagem oficial pode gravar como root em bind mounts no Linux.
if [[ ! -O index.html || ! -O aula-bancos-de-dados.pdf ]]; then
  compose run --rm --no-deps --entrypoint chown marp "$(id -u):$(id -g)" index.html aula-bancos-de-dados.pdf
fi
echo "Gerados: $ROOT_DIR/index.html e $ROOT_DIR/aula-bancos-de-dados.pdf"
