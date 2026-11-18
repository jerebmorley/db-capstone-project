"""Fixtures de los tests de integración.

Los tests corren contra un MySQL y un PostgreSQL reales, pero en un stack
propio (proyecto Docker "little-lemon-test", puertos 3309 y 5436) creado con
los valores falsos de .env.example. Nunca tocan tus bases ni leen tu .env:
las variables de entorno del proceso se reemplazan por las de prueba.
"""

import os
import subprocess
from pathlib import Path

import pytest

from db_connections import conectar_mysql, conectar_postgres

RAIZ = Path(__file__).resolve().parents[1]
PROYECTO = "little-lemon-test"
PUERTOS_TEST = {"DB_PORT": "3309", "PG_PORT": "5436"}

TABLAS_RAW = [
    "cuisines", "customers", "deliverystatuses", "menucategories", "menuitems",
    "menuproducts", "menus", "orderdeliveryhistory", "orderdetails", "orders",
    "reservations", "restauranttables", "staff", "staffroles",
]


def entorno_de_prueba():
    """Variables de .env.example (valores falsos) con los puertos de test."""
    variables = {}
    for linea in (RAIZ / ".env.example").read_text(encoding="utf-8").splitlines():
        linea = linea.strip()
        if linea and not linea.startswith("#") and "=" in linea:
            clave, valor = linea.split("=", 1)
            variables[clave] = valor
    variables.update(PUERTOS_TEST)
    return variables


def compose(*args, entorno):
    comando = ["docker", "compose", "-p", PROYECTO, "--env-file", ".env.example", *args]
    try:
        subprocess.run(comando, cwd=RAIZ, env=entorno, check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)
    except FileNotFoundError:
        pytest.exit("Los tests de integración necesitan Docker con Compose.")
    except subprocess.CalledProcessError as error:
        pytest.exit(f"Falló `docker compose {' '.join(args)}`:\n{error.stderr}")


@pytest.fixture(scope="session", autouse=True)
def stack_de_prueba():
    """Levanta el stack de test al inicio de la sesión y lo borra al final."""
    variables = entorno_de_prueba()
    anterior = {clave: os.environ.get(clave) for clave in variables}
    # Las variables de la terminal (por ejemplo, tu .env cargado) tienen
    # prioridad en compose y en los scripts: se pisan con las de prueba.
    os.environ.update(variables)
    entorno = dict(os.environ)

    compose("down", "-v", entorno=entorno)  # por si quedó uno de una corrida cortada
    compose("up", "-d", "--wait", "--wait-timeout", "300", entorno=entorno)
    yield
    compose("down", "-v", entorno=entorno)

    for clave, valor in anterior.items():
        if valor is None:
            os.environ.pop(clave, None)
        else:
            os.environ[clave] = valor


@pytest.fixture
def mysql():
    conexion = conectar_mysql()
    conexion.autocommit = True
    yield conexion
    conexion.close()


@pytest.fixture
def pg():
    conexion = conectar_postgres()
    conexion.autocommit = True
    yield conexion
    conexion.close()


@pytest.fixture(autouse=True)
def warehouse_vacio(pg):
    """Cada test arranca con raw y meta vacíos y sin constraints de falla."""
    pg.execute("ALTER TABLE raw.orders DROP CONSTRAINT IF EXISTS falla_de_prueba")
    pg.execute("ALTER TABLE meta.extract_runs DROP CONSTRAINT IF EXISTS falla_de_prueba")
    tablas = ", ".join(f"raw.{t}" for t in TABLAS_RAW)
    pg.execute(f"TRUNCATE {tablas}, meta.watermarks, meta.extract_runs")
    pg.execute("ALTER SEQUENCE meta.batch_id_seq RESTART")
    yield
