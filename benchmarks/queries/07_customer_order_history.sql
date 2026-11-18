-- Historial de un cliente con el contacto vigente en cada pedido (consulta puntual).
SELECT
    f.order_id,
    f.ordered_at,
    f.channel,
    f.total_cost,
    f.final_status,
    c.contact_number
FROM marts.fct_orders AS f
JOIN marts.dim_customers AS c ON c.customer_key = f.customer_key
WHERE f.customer_id = 12345
ORDER BY f.ordered_at
