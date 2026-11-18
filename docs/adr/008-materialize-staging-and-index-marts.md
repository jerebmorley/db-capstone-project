# ADR-008: Staging e intermediate como tablas, ANALYZE e índices puntuales

- **Estado:** aceptada (reemplaza el punto 3 del ADR-005 sobre materializar
  staging como vistas)
- **Fecha:** 2026-11-18

## Contexto

El ADR-005 hizo de staging una capa de vistas y el ADR-006 hizo lo mismo con
intermediate, a la espera de medir. La medición (ver
[docs/performance.md](../performance.md)) mostró que:

- cada test y cada modelo que lee esas vistas recalcula la deduplicación de
  millones de filas; en `dbt build` los tests sumaban ~100 s y los hechos
  tardaban 19–27 s;
- la deduplicación ordena 2,3 M filas en disco;
- la consulta puntual de un cliente recorre todo `fct_orders`;
- las tablas recién creadas quedan sin estadísticas hasta que autovacuum las
  analiza, y las chicas nunca.

## Decisión

1. Staging e intermediate se materializan como **tablas**.
2. Cada tabla que crea dbt corre `ANALYZE` al terminar (`post-hook`).
3. Índices solo para consultas puntuales: `fct_orders(customer_id)` y
   `dim_customers(customer_key)` único.
4. No se agregan índices en raw ni modelos incrementales: el índice en raw
   empeoró la construcción de staging, y el build (~40 s por hora) no
   necesita incrementales.

## Consecuencias

- `dbt build` baja de 50–57 s a 37–42 s; los tests, de ~100 s a ~30 s de
  suma; la consulta puntual, de ~70 ms a 0,1 ms.
- Se usan ~340 MB más de disco (staging e intermediate como tablas).
- Staging deja de reflejar raw al instante: refleja la última corrida de dbt.
- Las consultas que agregan tablas enteras no cambian: ya tardan menos de
  medio segundo y ningún índice las acelera.
- Ajustar `work_mem` de PostgreSQL podría evitar que el ordenamiento vaya a
  disco; queda fuera de este incremento.
