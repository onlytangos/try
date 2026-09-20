#!/bin/bash

OK=1

# verificar git instalado
if ! command -v git &> /dev/null; then
  echo "Git no instalado. Ejecuta: sudo apt install git"
  OK=0
fi

# verificar clave SSH existe
if [ ! -f ~/.ssh/id_ed25519 ]; then
  echo "Clave SSH no encontrada. Ejecuta:"
  echo "  ssh-keygen -t ed25519 -C 'onlytango@proton.me'"
  echo "  cat ~/.ssh/id_ed25519.pub  (añadir en github.com/settings/keys)"
  OK=0
fi

# verificar conexion SSH con github
if [ $OK -eq 1 ]; then
  ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"
  if [ $? -ne 0 ]; then
    echo "SSH con GitHub no funciona. Verifica la clave en github.com/settings/keys"
    OK=0
  fi
fi

if [ $OK -eq 1 ]; then
  echo "OK: git y SSH listos"
  exit 0
else
  exit 1
fi
