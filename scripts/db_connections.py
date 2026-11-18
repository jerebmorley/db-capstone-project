"""Conexiones a MySQL (origen) y PostgreSQL (warehouse) desde variables de entorno.

Cada función valida sus variables y termina con un mensaje claro si falta
alguna. Los drivers se importan adentro para que un script que usa solo una
base no necesite el driver de la otra.
"""

import os
import sys

VARIABLES_MYSQL = ["DB_HOST", "DB_PORT", "DB_USER", "DB_PASSWORD", "DB_NAME"]
VARIABLES_POSTGRES = ["PG_HOST", "PG_PORT", "PG_DB", "PG_USER", "PG_PASSWORD"]


def _exigir(variables):
    faltantes = [v for v in variables if not os.environ.get(v)]
    if faltantes:
        sys.exit(
            "Faltan variables de entorno: " + ", ".join(faltantes) + ".\n"
            "Copiá .env.example a .env, completalo y cargalo con:\n"
            "  set -a; source .env; set +a"
        )


def conectar_mysql():
    _exigir(VARIABLES_MYSQL)
    import mysql.connector

    return mysql.connector.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ["DB_PORT"]),
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        database=os.environ["DB_NAME"],
    )


def conectar_postgres():
    _exigir(VARIABLES_POSTGRES)
    import psycopg

    return psycopg.connect(
        host=os.environ["PG_HOST"],
        port=int(os.environ["PG_PORT"]),
        dbname=os.environ["PG_DB"],
        user=os.environ["PG_USER"],
        password=os.environ["PG_PASSWORD"],
    )
