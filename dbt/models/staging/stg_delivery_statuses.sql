-- Estados posibles de un pedido.
-- Una fila por deliverystatusid (la versión vigente en raw).

with source as (
    {{ latest_version(source('raw', 'deliverystatuses'), 'deliverystatusid') }}
),

renamed as (
    select
        deliverystatusid as delivery_status_id,
        statusname       as status_name,
        updatedat        as updated_at
    from source
)

select * from renamed
