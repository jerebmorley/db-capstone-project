import mysql.connector as connector
from getpass import getpass

conexion = connector.connect(
    host="127.0.0.1",
    port=3306,
    user="jeremias",
    password="jeremias!",
    database="little_lemon_restaurante",
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
