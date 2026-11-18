-- Clientes del restaurante.
-- Una fila por customerid (la versión vigente en raw).

with source as (
    {{ latest_version(source('raw', 'customers'), 'customerid') }}
),

renamed as (
    select
        customerid    as customer_id,
        fullname      as full_name,
        contactnumber as contact_number,
        email         as email,
        updatedat     as updated_at
    from source
)

select * from renamed
