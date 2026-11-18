-- Personal. Incluye salario: dato sensible.
-- Una fila por staffid (la versión vigente en raw).

with source as (
    {{ latest_version(source('raw', 'staff'), 'staffid') }}
),

renamed as (
    select
        staffid   as staff_id,
        fullname  as full_name,
        roleid    as role_id,
        salary    as salary,
        email     as email,
        updatedat as updated_at
    from source
)

select * from renamed
