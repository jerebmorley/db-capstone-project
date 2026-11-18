-- La suma de las líneas tiene que dar la suma de los totales de los pedidos.

with totals as (
    select
        (select sum(line_total) from {{ ref('fct_order_lines') }}) as lines_total,
        (select sum(total_cost) from {{ ref('fct_orders') }})      as orders_total
)

select * from totals where lines_total <> orders_total
