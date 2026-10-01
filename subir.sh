#!/bin/bash
# Este script vive en la carpeta "publicar" (junto con .git y check.sh)
# La carpeta superior (BASE) contiene datos.js, index.htm y M/
# NOTA: el disco es exFAT/NTFS y no soporta symlinks, asi que se copia.
# datos.js e index.htm SIEMPRE se suben tal cual estan en local,
# nunca se dejan mezclar (merge) con lo que hubiera en remoto.
# no se toca los archivos originales ni los videos de la carpeta M
# CTRL+F5 para forzar la recarga
#
# PREPARACIÓN (UNA VEZ) para usarlo desde cualquier máquina
# ---------------------------------------------------------------------
# 1. Generar la clave en BASE (NO en publicar: se subiría al repo público):
#      ssh-keygen -t ed25519 -f ../.deploy_key -C onlytangos-try-deploy
# 2. En GitHub: onlytangos/try → Settings → Deploy keys → Add deploy key
#      - pegar el contenido de ../.deploy_key.pub
#      - marcar "Allow write access"
#    (es otra clave distinta a la de tangoinfo: GitHub no deja repetir
#     una deploy key en dos repos)
#
# url: https://onlytangos.github.io/try/

NOMBRE="koko"
EMAIL="55tgb@protonmail.com"

REPO=$(cd "$(dirname "$0")" && pwd)
BASE=$(dirname "$REPO")

no_listo() {
  echo "ERROR: $1"
  echo ">> leer al inicio del script: PREPARACIÓN (UNA VEZ)"
  exit 1
}

# verificar dependencias
bash "$REPO/check.sh"
if [ $? -ne 0 ]; then
  echo "Abortando push hasta resolver los problemas anteriores."
  exit 1
fi
command -v ssh >/dev/null    || no_listo "ssh no está instalado"
[ -f "$BASE/.deploy_key" ]   || no_listo "falta la clave $BASE/.deploy_key"

# ssh rechaza claves con permisos abiertos (exFAT/NTFS no permiten chmod) → copia temporal
KEY=$(mktemp)
cp "$BASE/.deploy_key" "$KEY"; chmod 600 "$KEY"
trap 'rm -f "$KEY"' EXIT
export GIT_SSH_COMMAND="ssh -i $KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"

# git con la configuración que necesita el disco externo, sin depender de la máquina
G() { git -C "$REPO" -c safe.directory='*' -c core.fileMode=false -c user.name="$NOMBRE" -c user.email="$EMAIL" "$@"; }

G ls-remote origin >/dev/null 2>&1 || no_listo "GitHub no acepta la clave (¿deploy key añadida con write access?) o no hay red"

# descomenta si : Borres la carpeta .git accidentalmente, Muevas el proyecto a otra carpeta, Empieces un repo nuevo desde cero
#G init
#G remote add origin git@github.com:onlytangos/try.git

# Traer primero lo que haya en remoto
G pull origin master --allow-unrelated-histories --no-edit --no-rebase
if [ $? -ne 0 ]; then
  echo ""
  echo "El pull ha tenido conflictos que Git no ha podido resolver solo."
  echo "Revisa 'git status', resuelve los conflictos, luego:"
  echo "  git add ."
  echo "  git commit"
  echo "  git push -u origin master"
  exit 1
fi

# Forzar que datos.js, index.htm y M queden EXACTAMENTE como en local,
# pisando cualquier fusion que el pull haya podido hacer.
cp "$BASE/datos.js"  "$REPO/datos.js"
cp "$BASE/index.htm" "$REPO/index.htm"
if command -v rsync >/dev/null; then
  rsync -a --delete "$BASE/M/" "$REPO/M/"
else
  # Windows Git Bash no trae rsync
  rm -rf "$REPO/M" && cp -r "$BASE/M" "$REPO/M"
fi

G add .
G commit -m "${1:-actualizacion}" || echo "sin cambios"

G push -u origin master && echo ">> publicado: https://onlytangos.github.io/try/"
