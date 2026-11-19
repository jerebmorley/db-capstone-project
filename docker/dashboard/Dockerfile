# Dashboard de Streamlit sobre los marts (dashboard/app.py).
FROM python:3.12-slim

WORKDIR /app
COPY requirements-dashboard.txt .
RUN pip install --no-cache-dir -r requirements-dashboard.txt \
 && useradd --create-home dashboard

COPY .streamlit/ .streamlit/
COPY scripts/db_connections.py scripts/
COPY dashboard/ dashboard/

USER dashboard
EXPOSE 8501
CMD ["streamlit", "run", "dashboard/app.py", "--server.address=0.0.0.0", "--server.port=8501"]
