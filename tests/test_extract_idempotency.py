"""Idempotencia del extractor MySQL -> raw (ver docs/adr/004).

Se prueba que:
  * sin cambios en MySQL, correrlo de nuevo no agrega filas;
  * solo trae lo que cambió, respetando el margen de seguridad;
  * si falla a mitad de una tabla, no queda nada a medias (ni filas ni
    watermark) y el reintento carga cada fila exactamente una vez;
  * no corren dos extracciones a la vez.
Las fallas se provocan con constraints CHECK temporales en PostgreSQL, sin
tocar el código del extractor.
"""

import time

import psycopg
import pytest

import extract_mysql_to_raw as extractor

# Clave de cada tabla (en raw, en minúscula), para detectar versiones repetidas.
CLAVES = {
    "Cuisines": "cuisine", "Customers": "customerid",
    "DeliveryStatuses": "deliverystatusid", "MenuCategories": "categoryid",
    "MenuItems": "menuitemsid", "MenuProducts": "productid", "Menus": "menuid",
    "OrderDeliveryHistory": "historyid", "OrderDetails": "orderdetailid",
    "Orders": "orderid", "Reservations": "reservationid",
    "RestaurantTables": "tablenumber", "Staff": "staffid", "StaffRoles": "roleid",
}
ANTES_DE_ORDERS = extractor.TABLAS[: extractor.TABLAS.index("Orders")]
DESPUES_DE_ORDERS = extractor.TABLAS[extractor.TABLAS.index("Orders") + 1:]


def extraer(*args):
    """Corre el extractor sin margen (salvo que se indique otro)."""
    argv = list(args)
    if "--lag-seconds" not in argv:
        argv += ["--lag-seconds", "0"]
    return extractor.main(argv)


def filas_mysql(mysql, tabla):
    cursor = mysql.cursor()
    cursor.execute(f"SELECT COUNT(*) FROM `{tabla}`")
    total = cursor.fetchone()[0]
    cursor.close()
    return total


def filas_raw(pg, tabla):
    return pg.execute(f"SELECT COUNT(*) FROM raw.{tabla.lower()}").fetchone()[0]


def watermark(pg, tabla):
    fila = pg.execute(
        "SELECT high_watermark FROM meta.watermarks WHERE table_name = %s", (tabla,)
    ).fetchone()
    return fila[0] if fila else None


def cambiar_telefono(mysql, customer_id):
    """Cambia un cliente con un valor siempre nuevo (si no cambia, UpdatedAt tampoco)."""
    cursor = mysql.cursor()
    cursor.execute(
        "UPDATE Customers SET ContactNumber = %s WHERE CustomerID = %s",
        (str(time.time_ns())[-10:], customer_id),
    )
    cursor.close()


def test_carga_completa_coincide_con_mysql(mysql, pg):
    assert extraer() == 0
    for tabla in extractor.TABLAS:
        assert filas_raw(pg, tabla) == filas_mysql(mysql, tabla), tabla


def test_segunda_corrida_no_agrega_filas(mysql, pg):
    extraer()
    antes = {t: filas_raw(pg, t) for t in extractor.TABLAS}
    extraer()
    assert {t: filas_raw(pg, t) for t in extractor.TABLAS} == antes
    cargadas = pg.execute(
        "SELECT COALESCE(SUM(rows_loaded), 0) FROM meta.extract_runs WHERE batch_id = 2"
    ).fetchone()[0]
    assert cargadas == 0


def test_solo_trae_filas_modificadas(mysql, pg):
    extraer()
    antes = {t: filas_raw(pg, t) for t in extractor.TABLAS}
    cambiar_telefono(mysql, 5)
    extraer()
    for tabla in extractor.TABLAS:
        esperado = antes[tabla] + (1 if tabla == "Customers" else 0)
        assert filas_raw(pg, tabla) == esperado, tabla
    # La versión vieja y la nueva conviven en raw (append-only).
    versiones = pg.execute(
        "SELECT COUNT(DISTINCT contactnumber) FROM raw.customers WHERE customerid = 5"
    ).fetchone()[0]
    assert versiones == 2


def test_margen_no_trae_cambios_recientes(mysql, pg):
    extraer()
    cambiar_telefono(mysql, 6)
    extraer("--lag-seconds", "30")
    assert filas_raw(pg, "Customers") == filas_mysql(mysql, "Customers")
    extraer()  # sin margen, ahora sí llega
    assert filas_raw(pg, "Customers") == filas_mysql(mysql, "Customers") + 1


def test_falla_durante_copy_no_deja_nada(mysql, pg):
    # El COPY de Orders ya cargó varias filas cuando la 100 viola el CHECK.
    pg.execute("ALTER TABLE raw.orders ADD CONSTRAINT falla_de_prueba CHECK (orderid <> 100)")
    with pytest.raises(psycopg.errors.CheckViolation):
        extraer()
    assert filas_raw(pg, "Orders") == 0
    assert watermark(pg, "Orders") is None
    for tabla in ANTES_DE_ORDERS:  # se commitearon antes de la falla
        assert filas_raw(pg, tabla) == filas_mysql(mysql, tabla), tabla
    for tabla in DESPUES_DE_ORDERS:  # la corrida se cortó: no llegaron
        assert filas_raw(pg, tabla) == 0, tabla


def test_falla_antes_del_commit_no_avanza_watermark(mysql, pg):
    # Las filas de Orders y su watermark ya se escribieron; falla el último INSERT.
    pg.execute(
        "ALTER TABLE meta.extract_runs ADD CONSTRAINT falla_de_prueba "
        "CHECK (table_name <> 'Orders')"
    )
    with pytest.raises(psycopg.errors.CheckViolation):
        extraer()
    assert filas_raw(pg, "Orders") == 0
    assert watermark(pg, "Orders") is None


def test_reintento_tras_falla_carga_una_sola_vez(mysql, pg):
    pg.execute(
        "ALTER TABLE meta.extract_runs ADD CONSTRAINT falla_de_prueba "
        "CHECK (table_name <> 'Orders')"
    )
    with pytest.raises(psycopg.errors.CheckViolation):
        extraer()
    pg.execute("ALTER TABLE meta.extract_runs DROP CONSTRAINT falla_de_prueba")

    assert extraer() == 0
    for tabla in extractor.TABLAS:
        assert filas_raw(pg, tabla) == filas_mysql(mysql, tabla), tabla
    # El reintento (batch 2) no volvió a cargar las tablas que ya estaban.
    recargadas = pg.execute(
        "SELECT table_name FROM meta.extract_runs WHERE batch_id = 2 AND rows_loaded > 0"
    ).fetchall()
    assert {t for (t,) in recargadas} == {"Orders", *DESPUES_DE_ORDERS}


def test_raw_sin_versiones_duplicadas(mysql, pg):
    extraer()
    cambiar_telefono(mysql, 7)
    extraer()
    extraer()
    for tabla, clave in CLAVES.items():
        repetidas = pg.execute(
            f"SELECT COUNT(*) FROM (SELECT {clave}, updatedat FROM raw.{tabla.lower()} "
            f"GROUP BY {clave}, updatedat HAVING COUNT(*) > 1) x"
        ).fetchone()[0]
        assert repetidas == 0, tabla


def test_no_corren_dos_extracciones_a_la_vez(mysql, pg):
    # Simula una extracción en curso tomando el candado desde otra sesión.
    pg.execute("SELECT pg_advisory_lock(hashtext(%s))", (extractor.CANDADO,))
    try:
        with pytest.raises(SystemExit, match="otra extracción en curso"):
            extraer()
        for tabla in extractor.TABLAS:
            assert filas_raw(pg, tabla) == 0, tabla
    finally:
        pg.execute("SELECT pg_advisory_unlock(hashtext(%s))", (extractor.CANDADO,))
    assert extraer() == 0  # liberado el candado, corre normal
