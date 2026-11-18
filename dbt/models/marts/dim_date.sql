-- Dimensión de fechas: un día por fila, del primer al último pedido o reserva.
-- date_key es AAAAMMDD (ej.: 20260801), la clave que usan los hechos.

with limits as (
    select min(event_at)::date as first_day, max(event_at)::date as last_day
    from (
        select ordered_at as event_at from {{ ref('stg_orders') }}
        union all
        select reserved_for from {{ ref('stg_reservations') }}
    ) as events
),

days as (
    select generate_series(first_day, last_day, interval '1 day')::date as date_day
    from limits
)

select
    to_char(date_day, 'YYYYMMDD')::integer  as date_key,
    date_day,
    extract(year from date_day)::integer    as year,
    extract(quarter from date_day)::integer as quarter,
    extract(month from date_day)::integer   as month,
    to_char(date_day, 'FMMonth')            as month_name,
    extract(isodow from date_day)::integer  as day_of_week,
    to_char(date_day, 'FMDay')              as day_name,
    extract(isodow from date_day) in (6, 7) as is_weekend
from days
