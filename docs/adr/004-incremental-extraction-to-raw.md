# ADR-004: Extracción incremental MySQL → raw

- **Estado:** aceptada
- **Fecha:** 2026-11-18

## Contexto

El warehouse (PostgreSQL) necesita una copia de las 14 tablas de MySQL que
se mantenga al día sin copiar los 4,4 M de filas en cada corrida. Desde la
migración 001 (ADR-002) todas las tablas tienen `UpdatedAt` y las
cancelaciones no borran filas.

## Decisión

1. **Ventanas encadenadas.** Cada corrida extrae, por tabla, las filas con
   `UpdatedAt` en `(desde, hasta]`:
   - `desde` es el watermark guardado en `meta.watermarks`;
   - `hasta` es `NOW(6)` de MySQL menos un margen, igual para todas las
     tablas de la corrida.
   Como las ventanas se encadenan, cada instante cae en una sola ventana y no
   se pierden ni se repiten filas, aunque varias compartan `UpdatedAt`.
2. **Margen de seguridad (`--lag-seconds`, 30 s por defecto).** Una
   transacción toma `UpdatedAt` al ejecutar la sentencia pero se ve recién
   al hacer commit. Sin margen, una transacción que hace commit después de la
   extracción con un `UpdatedAt` anterior al nuevo watermark se perdería.
3. **Carga atómica.** Por tabla, en una sola transacción de PostgreSQL: `COPY`
   de las filas a `raw.<tabla>`, avance del watermark y registro en
   `meta.extract_runs`. Si algo falla, no avanza nada y la próxima corrida
   reintenta la misma ventana.
4. **Raw append-only.** Cada versión extraída de una fila es una fila nueva,
   con `_batch_id` y `_extracted_at`. Se conserva la historia de cambios
   (materia prima del SCD2 del incremento 10); la versión vigente la calcula
   staging tomando la de mayor `updatedat` por clave.
5. **Raw fiel al origen.** Mismos nombres de columna en minúscula, sin claves
   ni `NOT NULL`, con tipos equivalentes. Renombrar y limpiar es tarea de
   staging (dbt).
6. **Python + `COPY`.** `psycopg` 3 con `COPY ... FROM STDIN` y lectura de
   MySQL en lotes de 50.000 filas: memoria acotada y carga rápida.

## Consecuencias

- La carga inicial de 4,4 M de filas tarda unos 40 s y ocupa unos 380 MB en
  `raw`; una corrida sin cambios no trae nada.
- Los cambios aparecen en raw con hasta `--lag-seconds` de demora.
- Un `DELETE` físico hecho por fuera de los procedimientos no se detecta.
- Las tablas se extraen una tras otra: un pedido puede llegar en una corrida
  y sus detalles en la siguiente. Staging tiene que tolerarlo.
- `UpdatedAt` es `DATETIME` sin zona horaria: el watermark está en la hora
  del servidor MySQL (UTC en Docker), y raw la guarda como `timestamp` sin
  zona.
- Si cambia el schema de MySQL, hay que actualizar a mano
  `docker/postgres/initdb/01_create_raw_schema.sql`.
- Las tablas de catálogo no tienen índice en `UpdatedAt`; son chicas y no
  hace falta.
