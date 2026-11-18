-- Tipos de cocina del menú.
-- Una fila por cuisine (la versión vigente en raw).

with source as (
    {{ latest_version(source('raw', 'cuisines'), 'cuisine') }}
),

renamed as (
    select
        cuisine     as cuisine,
        description as description,
        updatedat   as updated_at
    from source
)

select * from renamed
