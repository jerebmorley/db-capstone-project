# Airflow 3.4 con el pipeline (extractor y dbt) en un entorno virtual aparte:
# Airflow y dbt fijan muchas dependencias y juntos pueden entrar en conflicto.
FROM apache/airflow:3.4.0-python3.12

USER root
COPY requirements.txt /tmp/requirements.txt
RUN python -m venv /opt/pipeline-venv \
 && /opt/pipeline-venv/bin/pip install --no-cache-dir -r /tmp/requirements.txt \
 && /opt/pipeline-venv/bin/pip check
USER airflow
