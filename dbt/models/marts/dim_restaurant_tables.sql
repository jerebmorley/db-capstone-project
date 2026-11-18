-- Dimensión de mesas del salón (SCD1).

select
    table_number,
    capacity
from {{ ref('stg_restaurant_tables') }}
