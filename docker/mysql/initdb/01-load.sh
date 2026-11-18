#!/bin/bash
# Carga el schema y los datos de Little Lemon. La imagen oficial de MySQL
# ejecuta este archivo solo en el primer arranque (volumen vacío).
set -euo pipefail

# Los dumps tienen el nombre de la base fijo.
if [ "${MYSQL_DATABASE}" != "little_lemon_restaurante" ]; then
    echo "[little-lemon] ERROR: DB_NAME debe ser little_lemon_restaurante (es '${MYSQL_DATABASE}')." >&2
    exit 1
fi

# Contraseña por variable de entorno para no pasarla en la línea de comandos.
export MYSQL_PWD="${MYSQL_ROOT_PASSWORD}"

echo "[little-lemon] Cargando schema (sin DEFINER)..."
# Sin DEFINER, triggers y procedimientos quedan a nombre del usuario que los crea.
sed -E 's/DEFINER=`[^`]+`@`[^`]+`//g' /seed/schema/little_lemon_schema.sql | mysql -uroot

echo "[little-lemon] Cargando datos..."
mysql -uroot little_lemon_restaurante < /seed/sample-data/little_lemon_data.sql

unset MYSQL_PWD
echo "[little-lemon] Carga completa."
