# Medición de rendimiento del warehouse

Informe del incremento 12: dónde se va el tiempo del pipeline y de las
consultas, qué se cambió con evidencia y qué se descartó. Decisiones en
[ADR-008](adr/008-materialize-staging-and-index-marts.md).

## Metodología

- **Datos:** copia aislada idéntica a la de desarrollo (generador con
  `--seed 42 --scale 1.0`: 4,4 M de filas en MySQL; mismas filas en `raw`).
- **Consultas:** 7 consultas de negocio en `benchmarks/queries/`, las que
  haría un dashboard, más el costo de la deduplicación de staging.
- **Herramienta:** `scripts/benchmark_warehouse.py`. Por consulta, una
  corrida de calentamiento descartada y 5 medidas con
  `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)`; se informa la mediana. Del plan
  saca el nodo con más tiempo propio y el peor error entre filas estimadas y
  reales.
- **Pipeline:** tiempos de `dbt build` por modelo y test (`run_results.json`)
  y de la extracción.
- **Repeticiones:** todo se midió dos veces (columnas 1 y 2).

**Límites:** es una máquina de desarrollo con otros contenedores corriendo
(incluido Airflow), así que los números sirven para comparar antes y después,
no como valores absolutos: la misma consulta varía hasta un 70% entre
corridas. PostgreSQL usa su configuración por defecto.

## Línea base: qué encontró la medición

| Hallazgo | Evidencia |
|---|---|
| MySQL usa el índice de `UpdatedAt` en la extracción incremental | `EXPLAIN ANALYZE`: *Index range scan on Orders using idx_orders_updatedat* |
| En `dbt build`, los tests tardan el doble que los modelos | suma de tiempos: tests 100–105 s, modelos 48–56 s |
| Los hechos tardan 19–27 s porque leen vistas que recalculan la deduplicación y el estado de pedidos | `fct_orders` 19–21 s, `fct_order_lines` 21–27 s |
| Contar la vista `stg_order_delivery_history` tarda ~2 s: ordena 2,3 M filas **en disco** (78 MB) y el planificador estima 11.681 filas cuando son 2,3 M | plan de la consulta 06 |
| Buscar el historial de un cliente recorre los 500 k pedidos y arma un hash con los 50 k clientes para devolver 9 filas | plan de la consulta 07: *Seq Scan fct_orders*, *Hash* sobre `dim_customers` |
| Las dimensiones chicas quedan sin estadísticas (`reltuples = -1`); autovacuum solo analiza las grandes, y unos segundos después de crearlas | `pg_stat_user_tables` |

## Experimentos

| | Cambio | Resultado | Decisión |
|---|---|---|---|
| A | staging e intermediate como **tablas**, más `ANALYZE` al crear cada tabla | tests 100 s → 60 s; hechos 4–11 s; consulta 06 de ~2 s a ~0,15 s | **aplicado** |
| B | índices en `fct_orders(customer_id)` y `dim_customers(customer_key)` | consulta 07 de ~70 ms a 0,1 ms (*Index Scan*); 7,5 MB | **aplicado** |
| C | índice en raw `(clave, updatedat desc, _batch_id desc)` para la deduplicación | el plan lo usa, pero construir staging pasa de 5–6 s a 8–10 s (leer en orden de índice es más lento que leer en secuencia y ordenar); +165 MB | descartado |
| D | estadísticas extendidas sobre `extract(hour from ordered_at)` (consulta 03) | la estimación no cambia (hace falta combinarla con `channel`) y el tiempo tampoco (~320 ms) | descartado |
| — | modelos incrementales en los hechos | no probado: con el build en ~40 s y una corrida por hora no hay problema que resolver | descartado por ahora |
| — | ajustar `work_mem` (para que el ordenamiento no vaya a disco) | configuración del servidor, fuera del alcance | pendiente |

## Antes y después

### Pipeline

| Etapa | Antes (1 / 2) | Después (1 / 2) |
|---|---:|---:|
| Extracción completa (4,4 M filas) | 43 s | 39 s (sin cambios en el código) |
| Extracción sin cambios | 0,4 s | 0,4 s |
| `dbt build` (reloj) | 57 s / 50 s | **37 s / 42 s** |
| Suma de tiempos de tests | 105 s / 100 s | **29 s / 35 s** |
| Suma de tiempos de modelos | 56 s / 48 s | 70 s / 73 s |
| `fct_orders` | 21 s / 19 s | **4 s** |
| `fct_order_lines` | 27 s / 21 s | **11 s** |

Los modelos suman más porque ahora staging escribe tablas (el modelo más
lento pasa a ser `stg_order_delivery_history`, 17 s), pero se calculan una
sola vez y todo lo que los usa (hechos y tests) es más rápido.

### Consultas (mediana en ms)

| Consulta | Antes (1 / 2) | Después (1 / 2) | Cambio |
|---|---:|---:|---|
| 01 ingresos por mes y canal | 179 / 309 | 154 / 140 | dentro del ruido |
| 02 top productos por trimestre | 488 / 731 | 411 / 407 | dentro del ruido |
| 03 cancelaciones por hora | 338 / 372 | 328 / 323 | sin cambio |
| 04 ocupación por día de semana | 44 / 40 | 24 / 30 | leve |
| 05 frecuencia de pedidos por cliente | 266 / 152 | 154 / 252 | dentro del ruido |
| 06 staging (deduplicación) | 2.095 / 1.941 | **153 / 275** | ~10x |
| 07 historial de un cliente | 76 / 71 | **0,1 / 0,1** | ~700x |

Las consultas 01–05 recorren tablas enteras para agregar: ningún índice las
acelera y ya están por debajo de medio segundo.

## Costo

- Disco: staging ocupa 302 MB e intermediate 39 MB, que antes eran vistas;
  los índices nuevos, 7,5 MB. Los marts siguen en ~250 MB.
- Staging deja de reflejar raw al instante: se actualiza en cada `dbt build`
  (cada hora con Airflow).

## Cómo repetirlo

```bash
set -a; source .env; set +a
.venv/bin/python scripts/benchmark_warehouse.py --label mi_medicion
```

Los planes completos quedan en `generated/benchmarks/mi_medicion/`.
