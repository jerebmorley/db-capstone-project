-- Dimensión de personal (SCD1). Sin salario: es un dato sensible que ninguna
-- pregunta de este mart necesita (sigue en staging.stg_staff).

select
    s.staff_id,
    s.full_name,
    s.role_id,
    r.role_name,
    s.email
from {{ ref('stg_staff') }} as s
left join {{ ref('stg_staff_roles') }} as r on r.role_id = s.role_id
