import os
import sys

import mysql.connector as connector
from getpass import getpass

VARIABLES_REQUERIDAS = ["DB_HOST", "DB_PORT", "DB_USER", "DB_PASSWORD", "DB_NAME"]

faltantes = [v for v in VARIABLES_REQUERIDAS if not os.environ.get(v)]
if faltantes:
    sys.exit(
        "Faltan variables de entorno: " + ", ".join(faltantes) + ".\n"
        "Copiá .env.example a .env, completalo y cargalo con:\n"
        "  set -a; source .env; set +a"
    )

conexion = connector.connect(
    host=os.environ["DB_HOST"],
    port=int(os.environ["DB_PORT"]),
    user=os.environ["DB_USER"],
    password=os.environ["DB_PASSWORD"],
    database=os.environ["DB_NAME"],
)

print(conexion.is_connected())

cursor = conexion.cursor()

cursor.execute("SELECT * FROM Customers")
resultados = cursor.fetchall()
for i in resultados:
    print(i)

cursor.execute("SHOW TABLES;")
resultados = cursor.fetchall()
print("Tablas de Little Lemon:")
for tabla in resultados:
    print(tabla[0])

print(" ")

cursor.execute("DESCRIBE Customers;")

for columna in cursor.fetchall():
    print(columna)

consulta = """
SELECT
    Customers.FullName,
    Customers.Email,
    Customers.ContactNumber,
    Orders.TotalCost
FROM Customers
INNER JOIN Orders
    ON Customers.CustomerID = Orders.CustomerID
WHERE Orders.TotalCost > %s;
"""

cursor.execute(consulta, (200,))

resultados = cursor.fetchall()

for cliente in resultados:
    print(cliente)

for nombre, email, telefono, total in resultados:
    print(f"Cliente: {nombre}")
    print(f"Email: {email}")
    print(f"Teléfono: {telefono}")
    print(f"Total del pedido: ${total}")
    print("-" * 40)
