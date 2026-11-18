# ADR-005: dbt Core v1 para la capa staging

- **Estado:** aceptada; el punto 3 (staging como vistas) lo reemplaza el
  [ADR-008](008-materialize-staging-and-index-marts.md)
- **Fecha:** 2026-11-18

## Contexto

`raw` es append-only y fiel al origen (ADR-004): varias versiones por fila,
columnas como `orderid` o `desertname` y columnas de control. Hace falta una
capa limpia sobre la que construir los marts, con tests de calidad de datos.

Al momento de decidir, dbt ofrece dos líneas:

- **dbt v2** (motor reescrito en Rust), que es la instalación por defecto.
  Su guía de migración lista como adaptadores BigQuery, Databricks, Redshift,
  Snowflake, ClickHouse (beta), Spark (beta) y DuckDB: **PostgreSQL no
  figura**.
- **dbt Core v1** (1.12.7) con `dbt-postgres` 1.11.0, que sigue soportado.

## Decisión

1. Usar **dbt Core 1.12.7 + dbt-postgres 1.11.0**, fijados en
   `requirements.txt`. Sin fijar, pip elige una beta de dbt-core (1.13.0b1).
2. Escribir el proyecto sin lo que v2 marca como incompatible (`--select` en
   vez de `--models`, `data_tests` y `arguments:` en los tests genéricos, sin
   claves YAML desconocidas), para facilitar una migración futura.
3. **Staging = una vista por tabla de raw**: la versión vigente de cada clave
   (macro `latest_version`: mayor `updatedat`, desempate por `_batch_id`),
   nombres en snake_case (`*_id`, `*_at`), sin columnas de control y sin
   lógica de negocio. Los valores de negocio quedan como en el origen
   (`'Cancelada'`).
4. `profiles.yml` versionado en `dbt/`: lee todo de las variables `PG_*`, sin
   secretos.
5. Macro `generate_schema_name` para que los schemas se llamen exactamente
   `staging` (y después `marts`), en vez de `staging_staging`.
6. Tests: `unique`/`not_null` en cada clave, `relationships` entre modelos,
   `accepted_values` en estados, un test singular de totales de pedidos y un
   unit test de la deduplicación.

## Consecuencias

- Con 4,4 M de filas, `dbt build` (14 vistas + 51 tests) tarda unos 16 s.
- Las vistas recalculan la deduplicación en cada consulta: contar
  `stg_order_delivery_history` (2,3 M de filas) tarda alrededor de 1 s. Los
  marts van a ser tablas; si staging molesta, el incremento 12 lo mide.
- Si dbt v2 suma PostgreSQL, hay que reevaluar. Volver a verificarlo antes
  de decisiones grandes.
- `stg_staff` expone el salario: los marts tienen que decidir si lo incluyen.
