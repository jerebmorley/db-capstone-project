"""Verifica que la base de Little Lemon quedó cargada como se espera.

Chequea los conteos de filas de las 14 tablas y que los totales de Orders
coincidan con sus OrderDetails. Sale con código 0 si todo está bien y 1 si
algo falla, para poder usarlo en la terminal, CI o Airflow.

Uso:
    set -a; source .env; set +a
    python scripts/verify_load.py                      # datos de muestra
    python scripts/verify_load.py --expected generated/expected_counts.json
"""

import argparse
import json
import os
import sys

import mysql.connector as connector

VARIABLES_REQUERIDAS = ["DB_HOST", "DB_PORT", "DB_USER", "DB_PASSWORD", "DB_NAME"]

# Filas esperadas con los datos de muestra (database/sample-data).
# Con datos sintéticos, los esperados vienen del JSON que escribe el generador.
CONTEOS_ESPERADOS = {
    "Cuisines": 4,
    "Customers": 100,
    "DeliveryStatuses": 6,
    "MenuCategories": 4,
    "MenuItems": 12,
    "MenuProducts": 36,
    "Menus": 12,
    "OrderDeliveryHistory": 842,
    "OrderDetails": 680,
    "Orders": 240,
    "Reservations": 102,
    "RestaurantTables": 20,
    "Staff": 20,
    "StaffRoles": 5,
}

# Pedidos cuyo Quantity/TotalCost no coincide con la suma de sus detalles.
CONSULTA_TOTALES_DESCUADRADOS = """
SELECT COUNT(*)
FROM Orders o
LEFT JOIN (
    SELECT OrderID,
           SUM(Quantity) AS cantidad,
           SUM(Quantity * UnitPrice) AS total
    FROM OrderDetails
    GROUP BY OrderID
) d ON d.OrderID = o.OrderID
WHERE o.Quantity <> COALESCE(d.cantidad, 0)
   OR o.TotalCost <> COALESCE(d.total, 0);
"""


def conectar():
    faltantes = [v for v in VARIABLES_REQUERIDAS if not os.environ.get(v)]
    if faltantes:
        sys.exit(
            "Faltan variables de entorno: " + ", ".join(faltantes) + ".\n"
            "Copiá .env.example a .env, completalo y cargalo con:\n"
            "  set -a; source .env; set +a"
        )
    return connector.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ["DB_PORT"]),
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        database=os.environ["DB_NAME"],
    )


def verificar_conteos(cursor, esperados):
    """Devuelve la cantidad de tablas con conteo distinto al esperado."""
    fallas = 0
    for tabla, esperado in esperados.items():
        if tabla not in CONTEOS_ESPERADOS:
            sys.exit(f"Tabla desconocida en los conteos esperados: {tabla}")
        # Solo se aceptan nombres de CONTEOS_ESPERADOS (chequeado arriba): es seguro.
        cursor.execute(f"SELECT COUNT(*) FROM `{tabla}`")
        obtenido = cursor.fetchone()[0]
        estado = "OK  " if obtenido == esperado else "FAIL"
        if obtenido != esperado:
            fallas += 1
        print(f"{estado} {tabla:<22} esperado={esperado:<8} obtenido={obtenido}")
    return fallas


def verificar_totales(cursor):
    """Devuelve 1 si hay pedidos con totales descuadrados, 0 si no."""
    cursor.execute(CONSULTA_TOTALES_DESCUADRADOS)
    descuadrados = cursor.fetchone()[0]
    estado = "OK  " if descuadrados == 0 else "FAIL"
    print(f"{estado} Orders vs OrderDetails  pedidos descuadrados={descuadrados}")
    return 0 if descuadrados == 0 else 1


def leer_esperados(argv):
    parser = argparse.ArgumentParser(description="Verifica la carga de Little Lemon.")
    parser.add_argument(
        "--expected",
        help="JSON con conteos esperados (lo escribe generate_synthetic_data.py)",
    )
    args = parser.parse_args(argv)
    if not args.expected:
        return CONTEOS_ESPERADOS
    with open(args.expected, encoding="utf-8") as f:
        return json.load(f)["counts"]


def main(argv=None):
    esperados = leer_esperados(argv)
    conexion = conectar()
    try:
        cursor = conexion.cursor()
        print("== Conteos de filas ==")
        fallas = verificar_conteos(cursor, esperados)
        print("\n== Consistencia de totales ==")
        fallas += verificar_totales(cursor)
    finally:
        conexion.close()

    total = len(esperados) + 1
    print(f"\n{total - fallas}/{total} chequeos OK")
    return 1 if fallas else 0


if __name__ == "__main__":
    sys.exit(main())
