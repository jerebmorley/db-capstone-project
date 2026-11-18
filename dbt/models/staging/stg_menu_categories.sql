-- Categorías de producto (entrante, principal, postre, bebida).
-- Una fila por categoryid (la versión vigente en raw).

with source as (
    {{ latest_version(source('raw', 'menucategories'), 'categoryid') }}
),

renamed as (
    select
        categoryid   as category_id,
        categoryname as category_name,
        updatedat    as updated_at
    from source
)

select * from renamed
