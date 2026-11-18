-- Productos que se pueden pedir, con su precio.
-- Una fila por productid (la versión vigente en raw).

with source as (
    {{ latest_version(source('raw', 'menuproducts'), 'productid') }}
),

renamed as (
    select
        productid   as product_id,
        productname as product_name,
        categoryid  as category_id,
        cuisine     as cuisine,
        price       as price,
        description as description,
        updatedat   as updated_at
    from source
)

select * from renamed
