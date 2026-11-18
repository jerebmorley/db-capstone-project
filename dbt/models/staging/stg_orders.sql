-- Pedidos. quantity y total_cost los calculan triggers en MySQL a partir de las líneas.
-- Una fila por orderid (la versión vigente en raw).

with source as (
    {{ latest_version(source('raw', 'orders'), 'orderid') }}
),

renamed as (
    select
        orderid           as order_id,
        menuid            as menu_id,
        customerid        as customer_id,
        reservationid     as reservation_id,
        staffid           as staff_id,
        orderdate         as ordered_at,
        quantity::integer as quantity,
        totalcost         as total_cost,
        updatedat         as updated_at
    from source
)

select * from renamed
