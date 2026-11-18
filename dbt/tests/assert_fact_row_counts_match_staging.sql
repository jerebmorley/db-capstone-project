-- Cada hecho tiene que tener exactamente una fila por fila de su staging:
-- un join mal hecho que duplique o pierda filas aparece acá.

with counts as (
    select 'fct_orders' as fact,
           (select count(*) from {{ ref('fct_orders') }})     as fact_rows,
           (select count(*) from {{ ref('stg_orders') }})     as staging_rows
    union all
    select 'fct_order_lines',
           (select count(*) from {{ ref('fct_order_lines') }}),
           (select count(*) from {{ ref('stg_order_details') }})
    union all
    select 'fct_reservations',
           (select count(*) from {{ ref('fct_reservations') }}),
           (select count(*) from {{ ref('stg_reservations') }})
)

select * from counts where fact_rows <> staging_rows
