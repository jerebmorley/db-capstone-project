# ADR-002: UpdatedAt en todas las tablas y cancelación por estado

- **Estado:** aceptada
- **Fecha:** 2026-11-18

## Contexto

El extractor incremental (incremento 7) va a copiar MySQL → PostgreSQL
trayendo solo lo que cambió desde la última corrida. Con el schema del
capstone eso no es posible:

- Ninguna tabla registra cuándo cambió una fila.
- `CancelOrder` y `CancelBooking` hacen `DELETE` físico. Una fila borrada no
  se puede extraer, así que el destino la seguiría mostrando como vigente.
- `CancelOrder` borra en cascada `OrderDetails` y `OrderDeliveryHistory`: se
  pierde el historial del pedido, y los borrados en cascada no disparan los
  triggers de `OrderDetails`.
- `CancelBooking` falla con un error de foreign key si la reserva tiene
  pedidos asociados (`Orders.ReservationID` no tiene `ON DELETE CASCADE`).

El modelo ya tiene estados de cancelación: `Reservations.ReservationStatus`
incluye `'Cancelada'`, y `DeliveryStatuses` incluye `'Cancelado'`.

## Decisión

1. Agregar `UpdatedAt DATETIME(6)` con `DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE
   CURRENT_TIMESTAMP(6)` a las 14 tablas, con índice en las 5 transaccionales
   (`Customers`, `Orders`, `OrderDetails`, `OrderDeliveryHistory`,
   `Reservations`).
2. Cancelar es un cambio de estado, no un borrado:
   - `CancelBooking` pasa la reserva de `'Confirmada'` a `'Cancelada'`.
   - `CancelOrder` inserta un evento `'Cancelado'` en `OrderDeliveryHistory`.
3. No agregar una columna `DeletedAt`: el estado ya expresa la cancelación, y
   tener dos formas de decir "cancelado" permitiría que se contradigan.
4. Aplicar el cambio como migración numerada
   (`database/migrations/001_…sql`) sin editar los dumps del capstone, que
   quedan como versión 0.
5. Mantener PascalCase (`UpdatedAt`) por consistencia con el schema MySQL. La
   conversión a snake_case se hace en el staging de dbt.

## Consecuencias

- El extractor puede filtrar por `UpdatedAt` y ve las cancelaciones como
  cambios normales (una reserva actualizada o un evento nuevo en el historial).
- Los pedidos cancelados siguen en `Orders`: quien consulte pedidos activos
  debe excluir los que tienen un evento `'Cancelado'`.
- `UpdatedAt` no se actualiza si un `UPDATE` deja la fila igual, y no detecta
  un `DELETE` hecho a mano por fuera de los procedimientos.
- Las migraciones corren solo al crear el volumen de Docker. No hay tabla de
  control de migraciones aplicadas; si hace falta, se adopta una herramienta
  (Flyway o similar) en un incremento futuro.
- `database/procedures/stored_procedures.sql` queda como referencia de la
  versión 0 y ya no refleja `CancelOrder` ni `CancelBooking`.
