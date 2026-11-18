-- Dimensión de productos, SCD2: una fila por versión (el precio de lista
-- cambia con el tiempo). Categoría y cocina van desnormalizadas.

select
    md5(p.product_id::text || '|' || p.valid_from::text) as product_key,
    p.product_id,
    p.product_name,
    p.price         as list_price,
    p.category_id,
    c.category_name,
    p.cuisine,
    p.description,
    p.valid_from,
    p.valid_to,
    p.is_current
from {{ ref('int_menu_product_versions') }} as p
left join {{ ref('stg_menu_categories') }} as c on c.category_id = p.category_id
