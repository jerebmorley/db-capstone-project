-- Eventos de estado de cada pedido (incluye cancelaciones, ver ADR-002).
-- Una fila por historyid (la versión vigente en raw).

with source as (
    {{ latest_version(source('raw', 'orderdeliveryhistory'), 'historyid') }}
),

renamed as (
    select
        historyid        as history_id,
        orderid          as order_id,
        deliverystatusid as delivery_status_id,
        statusdate       as status_at,
        notes            as notes,
        updatedat        as updated_at
    from source
)

select * from renamed
