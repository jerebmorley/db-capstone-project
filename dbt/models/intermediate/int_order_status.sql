-- Resume el historial de estados de cada pedido en una fila.
-- final_status es el último evento; un pedido cancelado tiene el evento
-- 'Cancelado' (ADR-002). completed_at es cuándo se entregó o canceló.

with events as (
    select
        h.order_id,
        h.history_id,
        h.status_at,
        s.status_name
    from {{ ref('stg_order_delivery_history') }} as h
    inner join {{ ref('stg_delivery_statuses') }} as s
        on s.delivery_status_id = h.delivery_status_id
),

ranked as (
    select
        *,
        row_number() over (
            partition by order_id order by status_at desc, history_id desc
        ) as recency
    from events
)

select
    order_id,
    max(status_name) filter (where recency = 1)                            as final_status,
    bool_or(status_name = 'Cancelado')                                     as is_cancelled,
    min(status_at)                                                         as first_status_at,
    max(status_at) filter (where status_name in ('Entregado', 'Cancelado')) as completed_at,
    count(*)                                                               as status_events
from ranked
group by order_id
