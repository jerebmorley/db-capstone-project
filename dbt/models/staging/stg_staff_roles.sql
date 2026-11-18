-- Roles del personal.
-- Una fila por roleid (la versión vigente en raw).

with source as (
    {{ latest_version(source('raw', 'staffroles'), 'roleid') }}
),

renamed as (
    select
        roleid    as role_id,
        rolename  as role_name,
        updatedat as updated_at
    from source
)

select * from renamed
