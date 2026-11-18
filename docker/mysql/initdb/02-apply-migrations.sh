#!/bin/bash
# Aplica en orden las migraciones de database/migrations, después de la carga
# del dump. Como toda la carpeta initdb, corre solo con el volumen vacío.
set -euo pipefail

export MYSQL_PWD="${MYSQL_ROOT_PASSWORD}"

# nullglob: si no hay migraciones, el for no itera (en vez de fallar).
shopt -s nullglob
for migracion in /seed/migrations/*.sql; do
    echo "[little-lemon] Aplicando migración $(basename "$migracion")..."
    mysql -uroot little_lemon_restaurante < "$migracion"
done

unset MYSQL_PWD
echo "[little-lemon] Migraciones aplicadas."
