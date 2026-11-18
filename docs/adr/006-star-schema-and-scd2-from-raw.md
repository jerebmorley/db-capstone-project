# ADR-006: Marts en estrella con SCD2 construido desde raw

- **Estado:** aceptada
- **Fecha:** 2026-11-18

## Contexto

Staging tiene la versión vigente de cada tabla del origen, con la forma del
modelo OLTP: responder "ventas por categoría y mes" requiere varios joins. El
negocio necesita una capa organizada para analizar, y algunas dimensiones
cambian con el tiempo (el contacto de un cliente, el precio de un producto):
los reportes históricos no deberían cambiar cuando cambia la dimensión.

## Decisión

1. **Esquema en estrella** en el schema `marts`, materializado como tablas:
   - hechos: `fct_orders` (pedido), `fct_order_lines` (línea) y
     `fct_reservations` (reserva);
   - dimensiones: `dim_customers` y `dim_menu_products` (SCD2), y
     `dim_menus`, `dim_staff`, `dim_restaurant_tables` y `dim_date` (SCD1).
   La lógica reutilizable va en `intermediate` (vistas): versiones SCD2 y
   `int_order_status` (estado final de cada pedido).
2. **SCD2 desde raw, no con snapshots de dbt.** raw es append-only
   (ADR-004) y ya tiene cada versión que vio el extractor; el macro
   `scd2_from_raw` calcula `[valid_from, valid_to)` con `lag`/`lead`. La
   historia se reconstruye con `dbt build` en cualquier momento. Un snapshot,
   en cambio, acumula estado propio: si se pierde, se pierde la historia, y
   solo ve los cambios entre corridas de dbt.
3. **La primera versión rige desde 1900-01-01**: no sabemos desde cuándo
   valía, y los pedidos anteriores a su `UpdatedAt` tienen que encontrar
   versión.
4. **Cada versión rige desde el inicio de su segundo.** `UpdatedAt` tiene
   microsegundos, pero `OrderDate` y `ReservationDate` solo segundos: sin
   este ajuste, un pedido hecho en el mismo segundo que el cambio apuntaba a
   la versión vieja (lo encontró la prueba). De varias versiones en el mismo
   segundo queda la última.
5. **Claves surrogadas** `md5(id || '|' || valid_from)`: determinísticas, la
   misma versión da la misma clave al reconstruir.
6. **Point-in-time join**: cada hecho apunta a la versión vigente en el
   momento del evento (`ordered_at`, `reserved_for`).
7. `fct_order_lines` guarda el precio cobrado (`unit_price`) y el de lista
   vigente (`list_price`).
8. `dim_staff` no incluye el salario.

## Consecuencias

- Con 4,4 M de filas, `dbt build` completo (14 vistas de staging, 3 de
  intermediate, 9 tablas de marts y 122 tests) tarda unos 34 s; los marts
  ocupan unos 250 MB. Una consulta trimestral por canal tarda unos 60 ms.
- La historia SCD2 es tan fina como la frecuencia del extractor: dos cambios
  entre corridas se ven como uno.
- Un pedido hecho en el mismo segundo que un cambio, pero antes, se asigna a
  la versión nueva.
- Las vistas de intermediate se recalculan en cada test: los tests de
  `int_order_status` tardan unos 8 s. El incremento 12 decide si conviene
  materializarlas.
- En el origen, `Orders.MenuID` no se relaciona con los productos del pedido
  (el pedido 1 tiene menú 5 y productos de otros menús). Se informa tal cual,
  sin inferir una relación.
