-- Hecho de líneas de pedido: una fila por producto pedido.
-- unit_price es el precio cobrado (viene del pedido); list_price es el de
-- lista vigente en ese momento, de la versión del producto (SCD2).

with lines as (
    select * from {{ ref('stg_order_details') }}
),

orders as (
    select order_id, ordered_at from {{ ref('stg_orders') }}
),

products as (
    select * from {{ ref('dim_menu_products') }}
)

select
    l.order_detail_id,
    l.order_id,
    p.product_key,
    l.product_id,
    to_char(o.ordered_at, 'YYYYMMDD')::integer as date_key,
    o.ordered_at,
    l.quantity,
    l.unit_price,
    p.list_price,
    l.quantity * l.unit_price as line_total
from lines as l
inner join orders as o on o.order_id = l.order_id
left join products as p
    on  p.product_id = l.product_id
    and o.ordered_at >= p.valid_from
    and o.ordered_at <  p.valid_to
