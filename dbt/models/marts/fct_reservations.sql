-- Hecho de reservas: una fila por reserva, con la ocupación de la mesa.
-- customer_key apunta a la versión del cliente vigente en la fecha reservada.

with reservations as (
    select * from {{ ref('stg_reservations') }}
),

tables as (
    select * from {{ ref('dim_restaurant_tables') }}
),

customers as (
    select * from {{ ref('dim_customers') }}
)

select
    r.reservation_id,
    c.customer_key,
    r.customer_id,
    r.table_number,
    to_char(r.reserved_for, 'YYYYMMDD')::integer as date_key,
    r.reserved_for,
    r.party_size,
    t.capacity,
    round(r.party_size::numeric / t.capacity, 2) as seat_utilization,
    r.reservation_status,
    r.reservation_status = 'Cancelada' as is_cancelled
from reservations as r
left join tables as t on t.table_number = r.table_number
left join customers as c
    on  c.customer_id = r.customer_id
    and r.reserved_for >= c.valid_from
    and r.reserved_for <  c.valid_to
