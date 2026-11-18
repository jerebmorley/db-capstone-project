-- Reservas de mesa.
-- Una fila por reservationid (la versión vigente en raw).

with source as (
    {{ latest_version(source('raw', 'reservations'), 'reservationid') }}
),

renamed as (
    select
        reservationid     as reservation_id,
        customerid        as customer_id,
        tablenumber       as table_number,
        reservationdate   as reserved_for,
        partysize         as party_size,
        reservationstatus as reservation_status,
        updatedat         as updated_at
    from source
)

select * from renamed
