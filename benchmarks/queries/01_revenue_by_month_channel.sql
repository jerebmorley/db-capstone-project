-- Ingresos y % de cancelación por mes y canal (todo el período).
SELECT
    d.year,
    d.month,
    f.channel,
    COUNT(*)                                             AS orders,
    SUM(f.total_cost) FILTER (WHERE NOT f.is_cancelled)  AS revenue,
    ROUND(100.0 * AVG(f.is_cancelled::int), 1)           AS cancel_pct
FROM marts.fct_orders AS f
JOIN marts.dim_date AS d ON d.date_key = f.date_key
GROUP BY d.year, d.month, f.channel
ORDER BY d.year, d.month, f.channel
