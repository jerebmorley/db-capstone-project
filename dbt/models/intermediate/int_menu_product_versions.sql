-- Todas las versiones de cada producto (sobre todo, cambios de precio) con su
-- rango de validez (SCD2). Lee raw directamente: staging solo tiene la vigente.

with versions as (
    {{ scd2_from_raw(source('raw', 'menuproducts'), 'productid') }}
)

select
    productid   as product_id,
    productname as product_name,
    categoryid  as category_id,
    cuisine,
    price,
    description,
    updatedat   as updated_at,
    valid_from,
    valid_to,
    is_current
from versions
