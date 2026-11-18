"""Genera datos sintéticos reproducibles para Little Lemon.

Agrega clientes, reservas, pedidos, detalles e historial de estados entre
2024-01-01 y 2026-07-31 (antes de los datos de muestra). Con la misma semilla
y escala produce exactamente las mismas filas. Ver docs/adr/003.

Se corre sobre una base recién cargada (docker compose down -v && up):
    set -a; source .env; set +a
    python scripts/generate_synthetic_data.py --seed 42 --scale 1.0
    python scripts/verify_load.py --expected generated/expected_counts.json
"""

import argparse
import json
import os
import random
import sys
import time
from datetime import date, datetime, timedelta

# Reusa la conexión y los conteos de muestra del verificador.
from verify_load import CONTEOS_ESPERADOS, conectar

FECHA_INICIO = date(2024, 1, 1)
FECHA_FIN = date(2026, 7, 31)  # los datos de muestra empiezan el 2026-08-01

# Volúmenes con --scale 1.0 (≈ 4,3 M de filas en total).
CLIENTES = 50_000
PEDIDOS_DELIVERY = 450_000
PROB_RESERVA = 0.75  # probabilidad de que una mesa esté reservada en una franja
FRANJAS = [(12, 0), (13, 30), (20, 0), (21, 30)]

# Pedidos por lote: cada lote se inserta y commitea junto con sus filas hijas.
PEDIDOS_POR_LOTE = 2_000
SALIDA = os.path.join("generated", "expected_counts.json")

NOMBRES = [
    "Lucia", "Mateo", "Sofia", "Benjamin", "Valentina", "Santiago", "Martina",
    "Joaquin", "Catalina", "Tomas", "Emilia", "Lautaro", "Julieta", "Thiago",
    "Camila", "Agustin", "Florencia", "Nicolas", "Paula", "Facundo", "Micaela",
    "Ignacio", "Carolina", "Federico", "Agustina", "Lucas", "Abril", "Bruno",
]
APELLIDOS = [
    "Gomez", "Fernandez", "Lopez", "Martinez", "Rodriguez", "Gonzalez", "Perez",
    "Sanchez", "Romero", "Diaz", "Alvarez", "Torres", "Ruiz", "Ramirez",
    "Flores", "Benitez", "Acosta", "Medina", "Herrera", "Suarez", "Aguirre",
    "Gimenez", "Gutierrez", "Pereyra", "Rojas", "Molina", "Castro", "Ortiz",
]

# Secuencias de estados (nombres de DeliveryStatuses) con su peso.
FLUJOS_SALON = [
    (["Pendiente", "En preparacion", "Listo", "Entregado"], 97),
    (["Pendiente", "Cancelado"], 3),
]
FLUJOS_DELIVERY = [
    (["Pendiente", "En preparacion", "Listo", "En camino", "Entregado"], 90),
    (["Pendiente", "Cancelado"], 6),
    (["Pendiente", "En preparacion", "Cancelado"], 4),
]
LINEAS_POR_PEDIDO = [(2, 33), (3, 50), (4, 17)]


class Azar:
    """Azar reproducible construido solo sobre random.random().

    Python garantiza que random() da la misma secuencia para la misma semilla
    entre versiones; choice/randint/choices no tienen esa garantía.
    """

    def __init__(self, semilla):
        self._r = random.Random(semilla)

    def decimal(self):
        return self._r.random()

    def entero(self, a, b):
        return a + int(self._r.random() * (b - a + 1))

    def elegir(self, secuencia):
        return secuencia[int(self._r.random() * len(secuencia))]

    def probabilidad(self, p):
        return self._r.random() < p

    def ponderado(self, opciones):
        total = sum(peso for _, peso in opciones)
        x = self._r.random() * total
        for valor, peso in opciones:
            x -= peso
            if x < 0:
                return valor
        return opciones[-1][0]

    def muestra(self, secuencia, k):
        """k elementos distintos (Fisher-Yates parcial)."""
        copia = list(secuencia)
        for i in range(k):
            j = i + int(self._r.random() * (len(copia) - i))
            copia[i], copia[j] = copia[j], copia[i]
        return copia[:k]


def leer_catalogos(cursor):
    cursor.execute("SELECT ProductID, Price FROM MenuProducts ORDER BY ProductID")
    productos = cursor.fetchall()
    cursor.execute("SELECT MenuID FROM Menus ORDER BY MenuID")
    menus = [m for (m,) in cursor.fetchall()]
    cursor.execute("SELECT TableNumber, Capacity FROM RestaurantTables ORDER BY TableNumber")
    mesas = cursor.fetchall()
    cursor.execute("SELECT StatusName, DeliveryStatusID FROM DeliveryStatuses")
    estados = dict(cursor.fetchall())
    cursor.execute(
        "SELECT r.RoleName, s.StaffID FROM Staff s "
        "JOIN StaffRoles r ON r.RoleID = s.RoleID ORDER BY s.StaffID"
    )
    staff = {}
    for rol, staff_id in cursor.fetchall():
        staff.setdefault(rol, []).append(staff_id)
    return productos, menus, mesas, estados, staff


def proximo_id(cursor, tabla, columna):
    cursor.execute(f"SELECT COALESCE(MAX(`{columna}`), 0) + 1 FROM `{tabla}`")
    return cursor.fetchone()[0]


def verificar_base_recien_cargada(cursor):
    """Aborta si la base no está exactamente en el estado de muestra."""
    for tabla, esperado in CONTEOS_ESPERADOS.items():
        cursor.execute(f"SELECT COUNT(*) FROM `{tabla}`")
        obtenido = cursor.fetchone()[0]
        if obtenido != esperado:
            sys.exit(
                f"La base no está recién cargada ({tabla}: {obtenido} filas, "
                f"se esperaban {esperado}).\n"
                "Recreala con: docker compose down -v && docker compose up -d --wait"
            )


SQL_INSERT = {
    "Customers": "INSERT INTO Customers (CustomerID, FullName, ContactNumber, Email, UpdatedAt) "
                 "VALUES (%s, %s, %s, %s, %s)",
    "Reservations": "INSERT INTO Reservations (ReservationID, CustomerID, TableNumber, "
                    "ReservationDate, PartySize, ReservationStatus, UpdatedAt) "
                    "VALUES (%s, %s, %s, %s, %s, %s, %s)",
    # Quantity y TotalCost arrancan en 0: los triggers de OrderDetails los calculan.
    "Orders": "INSERT INTO Orders (OrderID, MenuID, CustomerID, ReservationID, StaffID, "
              "OrderDate, Quantity, TotalCost, UpdatedAt) "
              "VALUES (%s, %s, %s, %s, %s, %s, 0, 0, %s)",
    "OrderDetails": "INSERT INTO OrderDetails (OrderDetailID, OrderID, ProductID, Quantity, "
                    "UnitPrice, UpdatedAt) VALUES (%s, %s, %s, %s, %s, %s)",
    "OrderDeliveryHistory": "INSERT INTO OrderDeliveryHistory (HistoryID, OrderID, "
                            "DeliveryStatusID, StatusDate, Notes, UpdatedAt) "
                            "VALUES (%s, %s, %s, %s, %s, %s)",
}
# Orden de inserción que respeta las foreign keys.
ORDEN_TABLAS = ["Customers", "Reservations", "Orders", "OrderDetails", "OrderDeliveryHistory"]


class Cargador:
    """Acumula filas por tabla y las inserta por lotes, en orden de FKs."""

    def __init__(self, conexion):
        self.conexion = conexion
        self.cursor = conexion.cursor()
        self.buffers = {t: [] for t in ORDEN_TABLAS}
        self.insertadas = {t: 0 for t in ORDEN_TABLAS}

    def agregar(self, tabla, fila):
        self.buffers[tabla].append(fila)

    def volcar(self):
        for tabla in ORDEN_TABLAS:
            filas = self.buffers[tabla]
            if filas:
                self.cursor.executemany(SQL_INSERT[tabla], filas)
                self.insertadas[tabla] += len(filas)
                self.buffers[tabla] = []
        self.conexion.commit()


def generar(conexion, semilla, escala):
    azar = Azar(semilla)
    cursor = conexion.cursor()
    verificar_base_recien_cargada(cursor)
    productos, menus, mesas, estados, staff = leer_catalogos(cursor)
    camareros, repartidores = staff["Camarero"], staff["Repartidor"]

    sig = {
        "Customers": proximo_id(cursor, "Customers", "CustomerID"),
        "Reservations": proximo_id(cursor, "Reservations", "ReservationID"),
        "Orders": proximo_id(cursor, "Orders", "OrderID"),
        "OrderDetails": proximo_id(cursor, "OrderDetails", "OrderDetailID"),
        "OrderDeliveryHistory": proximo_id(cursor, "OrderDeliveryHistory", "HistoryID"),
    }
    primer_pedido = sig["Orders"]
    cargador = Cargador(conexion)

    # Clientes. Sin fecha de alta en el schema: UpdatedAt = inicio del período.
    inicio = datetime.combine(FECHA_INICIO, datetime.min.time())
    n_clientes = max(1, round(CLIENTES * escala))
    clientes = []
    for _ in range(n_clientes):
        cid = sig["Customers"]
        sig["Customers"] += 1
        nombre = f"{azar.elegir(NOMBRES)} {azar.elegir(APELLIDOS)}"
        cargador.agregar("Customers", (
            cid, nombre, str(3624100000 + cid), f"cliente{cid:03d}@example.test", inicio,
        ))
        clientes.append(cid)
    cargador.volcar()

    dias = (FECHA_FIN - FECHA_INICIO).days + 1
    media_delivery = PEDIDOS_DELIVERY * escala / dias
    prob_reserva = min(1.0, PROB_RESERVA * escala)

    def armar_pedido(fecha_pedido, cliente, reserva_id, staff_id, flujos):
        return {
            "fecha": fecha_pedido, "cliente": cliente, "reserva": reserva_id,
            "staff": staff_id, "menu": azar.elegir(menus),
            "flujo": azar.ponderado(flujos),
            "lineas": [
                (prod_id, azar.entero(1, 4), precio)
                for prod_id, precio in azar.muestra(productos, azar.ponderado(LINEAS_POR_PEDIDO))
            ],
        }

    pedidos_en_lote = 0
    for n_dia in range(dias):
        dia = FECHA_INICIO + timedelta(days=n_dia)
        pedidos_del_dia = []

        # Reservas: una por mesa y franja como máximo (sin doble booking).
        for hora, minuto in FRANJAS:
            for mesa, capacidad in mesas:
                if not azar.probabilidad(prob_reserva):
                    continue
                fecha_reserva = datetime(dia.year, dia.month, dia.day, hora, minuto)
                cliente = azar.elegir(clientes)
                cancelada = azar.probabilidad(0.12)
                rid = sig["Reservations"]
                sig["Reservations"] += 1
                if cancelada:
                    actualizada = fecha_reserva - timedelta(hours=azar.entero(1, 48))
                else:
                    actualizada = fecha_reserva + timedelta(hours=2)
                cargador.agregar("Reservations", (
                    rid, cliente, mesa, fecha_reserva, azar.entero(1, capacidad),
                    "Cancelada" if cancelada else "Completada", actualizada,
                ))
                if not cancelada:
                    fecha_pedido = fecha_reserva + timedelta(minutes=azar.entero(5, 30))
                    pedidos_del_dia.append(armar_pedido(
                        fecha_pedido, cliente, rid, azar.elegir(camareros), FLUJOS_SALON))

        # Delivery: cantidad diaria alrededor de la media.
        for _ in range(int(azar.decimal() * 2 * media_delivery + 0.5)):
            fecha_pedido = datetime(dia.year, dia.month, dia.day, 11, 0) + timedelta(
                minutes=azar.entero(0, 12 * 60 - 1))
            pedidos_del_dia.append(armar_pedido(
                fecha_pedido, azar.elegir(clientes), None, azar.elegir(repartidores),
                FLUJOS_DELIVERY))

        # IDs en orden cronológico dentro del día, como en un sistema real.
        pedidos_del_dia.sort(key=lambda p: p["fecha"])
        for p in pedidos_del_dia:
            oid = sig["Orders"]
            sig["Orders"] += 1
            fecha_estado = p["fecha"]
            historial = []
            for i, estado in enumerate(p["flujo"]):
                if i > 0:
                    fecha_estado += timedelta(minutes=azar.entero(8, 25))
                historial.append((estado, fecha_estado))
            cargador.agregar("Orders", (
                oid, p["menu"], p["cliente"], p["reserva"], p["staff"], p["fecha"], fecha_estado,
            ))
            for prod_id, cantidad, precio in p["lineas"]:
                cargador.agregar("OrderDetails", (
                    sig["OrderDetails"], oid, prod_id, cantidad, precio, p["fecha"]))
                sig["OrderDetails"] += 1
            for estado, cuando in historial:
                cargador.agregar("OrderDeliveryHistory", (
                    sig["OrderDeliveryHistory"], oid, estados[estado], cuando, "Generado", cuando))
                sig["OrderDeliveryHistory"] += 1
            pedidos_en_lote += 1
            if pedidos_en_lote >= PEDIDOS_POR_LOTE:
                cargador.volcar()
                pedidos_en_lote = 0

        if dia.day == 1:
            print(f"  {dia:%Y-%m} ... {sum(cargador.insertadas.values()):,} filas", flush=True)

    cargador.volcar()

    # Los triggers pusieron UpdatedAt = ahora al calcular los totales:
    # se restaura al momento del último estado de cada pedido.
    print("  Ajustando UpdatedAt de Orders...", flush=True)
    cursor.execute(
        "UPDATE Orders o JOIN ("
        "  SELECT OrderID, MAX(StatusDate) AS ultimo FROM OrderDeliveryHistory"
        "  WHERE OrderID >= %s GROUP BY OrderID"
        ") h ON h.OrderID = o.OrderID SET o.UpdatedAt = h.ultimo",
        (primer_pedido,),
    )
    conexion.commit()
    return cargador.insertadas


def main(argv=None):
    parser = argparse.ArgumentParser(description="Genera datos sintéticos de Little Lemon.")
    parser.add_argument("--seed", type=int, default=42, help="semilla (default 42)")
    parser.add_argument("--scale", type=float, default=1.0,
                        help="factor de volumen; 1.0 ≈ 4,3 M de filas (default 1.0)")
    args = parser.parse_args(argv)
    if args.scale <= 0:
        sys.exit("--scale tiene que ser mayor que 0")

    conexion = conectar()
    t0 = time.monotonic()
    print(f"Generando con seed={args.seed} scale={args.scale}")
    try:
        insertadas = generar(conexion, args.seed, args.scale)
    finally:
        conexion.close()
    segundos = time.monotonic() - t0

    # Conteos esperados = muestra + lo insertado. El verificador los compara con la base.
    conteos = dict(CONTEOS_ESPERADOS)
    for tabla, n in insertadas.items():
        conteos[tabla] += n
    os.makedirs(os.path.dirname(SALIDA), exist_ok=True)
    with open(SALIDA, "w", encoding="utf-8") as f:
        json.dump({"seed": args.seed, "scale": args.scale, "counts": conteos}, f, indent=2)

    print(f"\nListo en {segundos:.0f} s. Filas insertadas:")
    for tabla, n in insertadas.items():
        print(f"  {tabla:<22} {n:>10,}")
    print(f"  {'Total':<22} {sum(insertadas.values()):>10,}")
    print(f"Conteos esperados en {SALIDA}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
