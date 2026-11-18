-- Top 10 productos por ingresos en cada trimestre de 2025 (sin pedidos cancelados).
WITH sales AS (
    SELECT
        d.year,
        d.quarter,
        p.product_name,
        SUM(l.line_total) AS revenue
    FROM marts.fct_order_lines AS l
    JOIN marts.fct_orders AS o ON o.order_id = l.order_id
    JOIN marts.dim_date AS d ON d.date_key = l.date_key
    JOIN marts.dim_menu_products AS p ON p.product_key = l.product_key
    WHERE d.year = 2025
      AND NOT o.is_cancelled
    GROUP BY d.year, d.quarter, p.product_name
)
SELECT *
FROM (
    SELECT *, rank() OVER (PARTITION BY year, quarter ORDER BY revenue DESC) AS ranking
    FROM sales
) AS ranked
WHERE ranking <= 10
ORDER BY year, quarter, ranking
