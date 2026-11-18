-- Costo de la deduplicación de staging (vista sobre 2,3 M filas de raw).
SELECT COUNT(*) FROM staging.stg_order_delivery_history
