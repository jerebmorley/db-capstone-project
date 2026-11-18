-- Cuántos clientes hicieron 1, 2, 3, ... pedidos no cancelados.
WITH per_customer AS (
    SELECT customer_id, COUNT(*) AS orders
    FROM marts.fct_orders
    WHERE NOT is_cancelled
    GROUP BY customer_id
)
SELECT orders AS orders_per_customer, COUNT(*) AS customers
FROM per_customer
GROUP BY orders
ORDER BY orders
