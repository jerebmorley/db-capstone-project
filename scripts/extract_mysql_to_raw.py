"""Extractor incremental MySQL -> PostgreSQL (schema raw).

Por cada tabla trae las filas con UpdatedAt en la ventana (desde, hasta]:
  desde = watermark de la corrida anterior (la primera vez, 1970-01-01)
  hasta = NOW(6) de MySQL menos un margen (--lag-seconds), igual para
          todas las tablas de la corrida
Las filas se agregan a raw.<tabla> (append-only). La carga, el avance del
watermark y el registro en meta.extract_runs van en una sola transacción:
si algo falla, no queda nada a medias. Ver docs/adr/004.

Uso:
    set -a; source .env; set +a
    python scripts/extract_mysql_to_raw.py
    python scripts/extract_mysql_to_raw.py --tables Orders Reservations --lag-seconds 0
"""

import argparse
import sys
import time
from datetime import datetime

from db_connections import conectar_mysql, conectar_postgres

# Tablas de MySQL a extraer; en raw se llaman igual, en minúscula.
TABLAS = [
    "Cuisines", "Customers", "DeliveryStatuses", "MenuCategories", "MenuItems",
    "MenuProducts", "Menus", "OrderDeliveryHistory", "OrderDetails", "Orders",
    "Reservations", "RestaurantTables", "Staff", "StaffRoles",
]
INICIO = datetime(1970, 1, 1)
FILAS_POR_LOTE = 50_000


def columnas_raw(pg, tabla_raw):
    """Columnas de datos de raw.<tabla> (sin las de control), en orden."""
    filas = pg.execute(
        "SELECT column_name FROM information_schema.columns "
        "WHERE table_schema = 'raw' AND table_name = %s AND column_name NOT LIKE '\\_%%' "
        "ORDER BY ordinal_position",
        (tabla_raw,),
    ).fetchall()
    if not filas:
        sys.exit(f"No existe raw.{tabla_raw}: ¿se creó el volumen de PostgreSQL con el schema raw?")
    return [c for (c,) in filas]


def leer_watermark(pg, tabla):
    fila = pg.execute(
        "SELECT high_watermark FROM meta.watermarks WHERE table_name = %s", (tabla,)
    ).fetchone()
    return fila[0] if fila else INICIO


def extraer_tabla(mysql, pg, tabla, batch_id, hasta):
    """Carga la ventana (watermark, hasta] de una tabla. Devuelve (desde, filas)."""
    tabla_raw = tabla.lower()
    columnas = columnas_raw(pg, tabla_raw)
    desde = leer_watermark(pg, tabla)
    inicio = datetime.now().astimezone()
    if hasta <= desde:
        return desde, 0

    # Nombres de tabla y columnas salen de TABLAS y del catálogo, no del usuario.
    lista_mysql = ", ".join(f"`{c}`" for c in columnas)
    lista_pg = ", ".join(columnas)
    cursor = mysql.cursor()
    filas = 0
    with pg.transaction():
        cursor.execute(
            f"SELECT {lista_mysql} FROM `{tabla}` WHERE UpdatedAt > %s AND UpdatedAt <= %s",
            (desde, hasta),
        )
        with pg.cursor().copy(
            f"COPY raw.{tabla_raw} ({lista_pg}, _batch_id) FROM STDIN"
        ) as copy:
            while lote := cursor.fetchmany(FILAS_POR_LOTE):
                for fila in lote:
                    copy.write_row((*fila, batch_id))
                filas += len(lote)
        pg.execute(
            "INSERT INTO meta.watermarks (table_name, high_watermark) VALUES (%s, %s) "
            "ON CONFLICT (table_name) DO UPDATE "
            "SET high_watermark = EXCLUDED.high_watermark, updated_at = now()",
            (tabla, hasta),
        )
        pg.execute(
            "INSERT INTO meta.extract_runs "
            "(batch_id, table_name, window_from, window_to, rows_loaded, started_at) "
            "VALUES (%s, %s, %s, %s, %s, %s)",
            (batch_id, tabla, desde, hasta, filas, inicio),
        )
    cursor.close()
    return desde, filas


def main(argv=None):
    parser = argparse.ArgumentParser(description="Extrae MySQL -> raw de forma incremental.")
    parser.add_argument("--tables", nargs="+", choices=TABLAS, metavar="TABLA",
                        help="tablas a extraer (default: todas)")
    parser.add_argument("--lag-seconds", type=int, default=30,
                        help="margen para transacciones en curso (default 30)")
    args = parser.parse_args(argv)
    if args.lag_seconds < 0:
        sys.exit("--lag-seconds no puede ser negativo")
    tablas = args.tables or TABLAS

    mysql = conectar_mysql()
    pg = conectar_postgres()
    pg.autocommit = True  # cada tabla abre su propia transacción explícita
    try:
        cursor = mysql.cursor()
        cursor.execute("SELECT NOW(6) - INTERVAL %s SECOND", (args.lag_seconds,))
        hasta = cursor.fetchone()[0]
        cursor.close()
        batch_id = pg.execute("SELECT nextval('meta.batch_id_seq')").fetchone()[0]
        print(f"Batch {batch_id}: extrayendo hasta {hasta} (margen {args.lag_seconds} s)")

        total, t0 = 0, time.monotonic()
        for tabla in tablas:
            t = time.monotonic()
            desde, filas = extraer_tabla(mysql, pg, tabla, batch_id, hasta)
            total += filas
            print(f"  {tabla:<22} desde {desde}  filas {filas:>10,}  {time.monotonic() - t:6.1f} s")
    finally:
        mysql.close()
        pg.close()

    print(f"Listo: {total:,} filas en {time.monotonic() - t0:.0f} s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
