#!/bin/bash
# Este script vive en la carpeta "publicar" (junto con .git y check.sh)
# La carpeta superior (BASE) contiene datos.js, index.htm y M/

REPO=$(cd "$(dirname "$0")" && pwd)
BASE=$(dirname "$REPO")

# verificar dependencias
bash "$REPO/check.sh"
if [ $? -ne 0 ]; then
  echo "Abortando push hasta resolver los problemas anteriores."
  exit 1
fi

# Asegurar que los enlaces simbolicos existen (sin copiar nada)
[ -L "$REPO/datos.js" ]  || ln -sf "$BASE/datos.js"  "$REPO/datos.js"
[ -L "$REPO/index.htm" ] || ln -sf "$BASE/index.htm" "$REPO/index.htm"
[ -L "$REPO/M" ]         || ln -sf "$BASE/M"          "$REPO/M"

# Subir a GitHub
cd "$REPO"
# descomenta si : Borres la carpeta .git accidentalmente, Muevas el proyecto a otra carpeta, Empieces un repo nuevo desde cero
#git init
#git remote add origin git@github.com:onlytangos/try.git
git add .
git commit -m "${1:-actualizacion}"
git push -u origin master

# url: https://onlytangos.github.io/try/
