-- Composición de cada menú. Corrige el nombre de origen desertname -> dessert_name.
-- Una fila por menuitemsid (la versión vigente en raw).

with source as (
    {{ latest_version(source('raw', 'menuitems'), 'menuitemsid') }}
),

renamed as (
    select
        menuitemsid as menu_items_id,
        coursename  as course_name,
        startername as starter_name,
        desertname  as dessert_name,
        drinkname   as drink_name,
        updatedat   as updated_at
    from source
)

select * from renamed
