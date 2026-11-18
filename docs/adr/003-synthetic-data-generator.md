# ADR-003: Generador de datos sintéticos reproducible

- **Estado:** aceptada
- **Fecha:** 2026-11-18

## Contexto

Los datos de muestra tienen 240 pedidos: con ese volumen todo es instantáneo
y no se puede medir el pipeline (carga incremental, índices, `EXPLAIN
ANALYZE`). Hace falta una base de millones de filas que cualquiera pueda
reconstruir idéntica a partir del repo.

## Decisión

1. Un script (`scripts/generate_synthetic_data.py`) que agrega clientes,
   reservas, pedidos, detalles e historial entre 2024-01-01 y 2026-07-31,
   antes de los datos de muestra. Con `--scale 1.0` son unos 4,4 M de filas.
   Los catálogos (menú, staff, mesas) no cambian.
2. Solo biblioteca estándar, sin Faker: Faker cambia sus datos entre
   versiones y rompería la reproducibilidad.
3. Todo el azar sale de `random.random()`, la única función cuya secuencia
   Python garantiza entre versiones para la misma semilla. `choice`,
   `randint` y `choices` no tienen esa garantía.
4. IDs explícitos y en orden cronológico, para no depender de
   `AUTO_INCREMENT`.
5. Los pedidos se insertan con total 0 y los triggers de `OrderDetails`
   calculan `Quantity` y `TotalCost`, igual que en la operación normal.
6. `UpdatedAt` refleja el último evento de cada fila (último estado del
   pedido, fecha de la reserva), no el momento de la generación. Así el
   extractor incremental tiene una historia real para recorrer.
7. El script aborta si la base no está recién cargada, y escribe los conteos
   esperados en `generated/expected_counts.json` para `verify_load.py`.

## Consecuencias

- Misma semilla y escala → mismas filas (verificado con una huella CRC32 por
  tabla sobre dos bases nuevas).
- Para llegar al volumen, el restaurante tiene unos 500 pedidos por día, la
  mayoría delivery: es poco realista para un local de 20 mesas. Se prioriza
  el volumen.
- Los clientes no tienen fecha de alta en el schema: su `UpdatedAt` es el
  inicio del período.
- Con `--scale 1.0` tarda unos 3 minutos y ocupa unos 550 MB de datos e
  índices (1,3 GB de volumen Docker).
- Si cambia el código del generador, cambian los datos aunque la semilla sea
  la misma: la reproducibilidad es por versión del script.
