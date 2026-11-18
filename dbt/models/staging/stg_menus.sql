-- Menús ofrecidos.
-- Una fila por menuid (la versión vigente en raw).

with source as (
    {{ latest_version(source('raw', 'menus'), 'menuid') }}
),

renamed as (
    select
        menuid      as menu_id,
        menuitemsid as menu_items_id,
        menuname    as menu_name,
        cuisine     as cuisine,
        updatedat   as updated_at
    from source
)

select * from renamed
