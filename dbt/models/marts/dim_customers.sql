-- Dimensión de clientes, SCD2: una fila por versión de cada cliente.
-- Los hechos apuntan a la versión vigente en el momento del evento.

select
    md5(customer_id::text || '|' || valid_from::text) as customer_key,
    customer_id,
    full_name,
    contact_number,
    email,
    valid_from,
    valid_to,
    is_current
from {{ ref('int_customer_versions') }}
