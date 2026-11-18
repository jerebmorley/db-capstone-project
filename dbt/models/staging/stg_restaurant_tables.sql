-- Mesas del salón y su capacidad.
-- Una fila por tablenumber (la versión vigente en raw).

with source as (
    {{ latest_version(source('raw', 'restauranttables'), 'tablenumber') }}
),

renamed as (
    select
        tablenumber as table_number,
        capacity    as capacity,
        updatedat   as updated_at
    from source
)

select * from renamed
