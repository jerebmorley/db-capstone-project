-- Todas las versiones de cada cliente con su rango de validez (SCD2).
-- Lee raw directamente: staging solo tiene la versión vigente.

with versions as (
    {{ scd2_from_raw(source('raw', 'customers'), 'customerid') }}
)

select
    customerid    as customer_id,
    fullname      as full_name,
    contactnumber as contact_number,
    email,
    updatedat     as updated_at,
    valid_from,
    valid_to,
    is_current
from versions
