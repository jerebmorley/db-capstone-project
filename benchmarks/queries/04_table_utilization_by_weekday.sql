-- Ocupación de mesas y cancelación de reservas por día de la semana.
SELECT
    d.day_of_week,
    d.day_name,
    COUNT(*)                                    AS reservations,
    ROUND(AVG(r.seat_utilization), 2)           AS avg_utilization,
    ROUND(100.0 * AVG(r.is_cancelled::int), 1)  AS cancel_pct
FROM marts.fct_reservations AS r
JOIN marts.dim_date AS d ON d.date_key = r.date_key
GROUP BY d.day_of_week, d.day_name
ORDER BY d.day_of_week
