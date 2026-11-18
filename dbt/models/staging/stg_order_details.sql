-- Líneas de cada pedido.
-- Una fila por orderdetailid (la versión vigente en raw).

with source as (
    {{ latest_version(source('raw', 'orderdetails'), 'orderdetailid') }}
),

renamed as (
    select
        orderdetailid     as order_detail_id,
        orderid           as order_id,
        productid         as product_id,
        quantity::integer as quantity,
        unitprice         as unit_price,
        updatedat         as updated_at
    from source
)

select * from renamed
