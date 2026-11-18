-- Pedidos cuyo quantity/total_cost no coincide con la suma de sus líneas.
-- Es el mismo chequeo de scripts/verify_load.py, sobre el warehouse.
-- El test pasa si la consulta no devuelve filas.

with details as (
    select
        order_id,
        sum(quantity)              as quantity,
        sum(quantity * unit_price) as total_cost
    from {{ ref('stg_order_details') }}
    group by order_id
)

select
    o.order_id,
    o.quantity,
    o.total_cost,
    d.quantity   as details_quantity,
    d.total_cost as details_total_cost
from {{ ref('stg_orders') }} as o
left join details as d on d.order_id = o.order_id
where o.quantity <> coalesce(d.quantity, 0)
   or o.total_cost <> coalesce(d.total_cost, 0)
