# ADR-007: Orquestación con Airflow 3 y LocalExecutor

- **Estado:** aceptada
- **Fecha:** 2026-11-18

## Contexto

El pipeline (extractor y `dbt build`) se corría a mano. Hace falta que corra
solo, en orden, con reintentos ante fallas pasajeras y con registro de cada
corrida. La máquina de desarrollo tiene 16 GB de RAM compartidos con otros
proyectos.

La versión vigente es Airflow 3.4.0. Su compose oficial usa `CeleryExecutor`
con Redis y un worker (8 servicios), pide al menos 4 GB, trae usuario
`airflow`/`airflow` y un secreto JWT por defecto, pasa todo el `.env` a los
contenedores y aclara que no está pensada para producción.

## Decisión

1. **Airflow 3.4.0 con `LocalExecutor`**: las tareas corren como procesos del
   scheduler. Servicios: `airflow-db`, `airflow-init` (una vez),
   `airflow-apiserver`, `airflow-scheduler` y `airflow-dag-processor`. Sin
   Celery, Redis, worker ni triggerer.
2. **Base de metadatos propia** (`airflow-db`), separada del warehouse.
3. **Profile `airflow`** en Compose: `docker compose up` sigue levantando solo
   MySQL y PostgreSQL.
4. **Imagen propia** (`docker/airflow/Dockerfile`) con el pipeline en un
   entorno virtual aparte (`/opt/pipeline-venv`), para que las dependencias
   de Airflow y de dbt no se pisen.
5. **Credenciales sin valores por defecto**: usuario y contraseña de la web,
   contraseña de la base de metadatos y secreto JWT salen del `.env`. A
   Airflow se le pasan solo las variables del pipeline, una por una.
6. **Código montado en solo lectura**; dbt escribe en `/tmp` y los logs de
   Airflow van a un volumen.
7. **DAG `little_lemon_elt`**: `extract_mysql_to_raw >> dbt_build`, cada hora,
   sin catchup, una corrida a la vez y pausado al crearse. La extracción
   reintenta 2 veces (es idempotente, ADR-004) y dbt 1.
8. **Candado en el extractor** (`pg_try_advisory_lock`): `max_active_runs`
   evita corridas simultáneas dentro de Airflow, pero no una manual en
   paralelo, que duplicaría la ventana de la otra.

## Consecuencias

- Los 3 servicios de Airflow usan unos 850 MB de RAM en reposo.
- La imagen pesa unos 3,8 GB.
- El usuario de la web se crea solo la primera vez: cambiar
  `AIRFLOW_ADMIN_PASSWORD` después no cambia la contraseña.
- No hay `FERNET_KEY`: Airflow no guarda conexiones ni secretos (las
  credenciales vienen del entorno), así que no hay nada que cifrar.
- Para producción haría falta otra cosa (Helm en Kubernetes, según la
  documentación oficial).
- Una alternativa futura es renderizar cada modelo de dbt como una tarea
  (por ejemplo, con Astronomer Cosmos); hoy `dbt build` es una sola tarea.
