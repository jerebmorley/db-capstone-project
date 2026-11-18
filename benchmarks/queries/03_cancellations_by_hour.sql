-- Pedidos y cancelaciones por hora del día y canal.
SELECT
    extract(hour FROM ordered_at)::int AS hour,
    channel,
    COUNT(*)                   AS orders,
    SUM(is_cancelled::int)     AS cancelled
FROM marts.fct_orders
GROUP BY 1, 2
ORDER BY 1, 2
