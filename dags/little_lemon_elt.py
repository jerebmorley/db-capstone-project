"""Pipeline ELT de Little Lemon: MySQL -> raw (extractor) -> staging/marts (dbt).

Corre cada hora. Las tareas usan el entorno /opt/pipeline-venv de la imagen
(docker/airflow/Dockerfile) y el código montado en /opt/little_lemon.
Ver docs/adr/007.
"""

from datetime import datetime, timedelta

from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG

VENV = "/opt/pipeline-venv/bin"
PROYECTO = "/opt/little_lemon"
# dbt escribe target/ y logs/ en /tmp: el código está montado en solo lectura.
DBT_FLAGS = (
    f"--project-dir {PROYECTO}/dbt --profiles-dir {PROYECTO}/dbt "
    "--target-path /tmp/dbt/target --log-path /tmp/dbt/logs"
)

with DAG(
    dag_id="little_lemon_elt",
    description="Extrae MySQL a raw y construye staging y marts con dbt",
    schedule="@hourly",
    start_date=datetime(2026, 11, 1),
    catchup=False,      # no corre las horas pasadas al activarlo
    max_active_runs=1,  # nunca dos corridas a la vez (además del candado del extractor)
    default_args={"retries": 1, "retry_delay": timedelta(minutes=2)},
    tags=["little_lemon", "elt"],
) as dag:
    extraer = BashOperator(
        task_id="extract_mysql_to_raw",
        bash_command=f"{VENV}/python {PROYECTO}/scripts/extract_mysql_to_raw.py",
        # Idempotente (ADR-004 y tests): reintentar no duplica filas.
        retries=2,
        retry_delay=timedelta(minutes=1),
    )

    transformar = BashOperator(
        task_id="dbt_build",
        bash_command=f"{VENV}/dbt build {DBT_FLAGS}",
    )

    extraer >> transformar
