-- Hecho de pedidos: una fila por pedido.
-- customer_key apunta a la versión del cliente vigente al hacer el pedido
-- (point-in-time join contra la dimensión SCD2).

with orders as (
    select * from {{ ref('stg_orders') }}
),

status as (
    select * from {{ ref('int_order_status') }}
),

customers as (
    select * from {{ ref('dim_customers') }}
)

select
    o.order_id,
    c.customer_key,
    o.customer_id,
    to_char(o.ordered_at, 'YYYYMMDD')::integer as date_key,
    o.staff_id,
    o.menu_id,
    o.reservation_id,
    case when o.reservation_id is null then 'delivery' else 'dine_in' end as channel,
    o.ordered_at,
    o.quantity,
    o.total_cost,
    s.final_status,
    coalesce(s.is_cancelled, false) as is_cancelled,
    s.completed_at,
    round(extract(epoch from s.completed_at - o.ordered_at) / 60)::integer as minutes_to_complete
from orders as o
left join customers as c
    on  c.customer_id = o.customer_id
    and o.ordered_at >= c.valid_from
    and o.ordered_at <  c.valid_to
left join status as s on s.order_id = o.order_id
