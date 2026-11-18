# Proyecto: Little Lemon → pipeline ELT de portfolio

## Qué es
Capstone de bases de datos (MySQL 8.4, caso Little Lemon) que estoy
convirtiendo en un proyecto de ingeniería de datos: MySQL (OLTP) →
PostgreSQL (raw/staging/marts) con dbt, orquestado con Airflow.
Plan completo en docs/ROADMAP.md.

## Sobre mí
Estudiante de 4to año de Ingeniería en Sistemas. Sé programar y SQL, pero
no tengo experiencia laboral en datos. Mi objetivo es aprender a trabajar
con IA y entender cada cambio.

## Reglas de trabajo
- Respondé en español rioplatense, directo y profesional.
- Un objetivo por tarea. Tocá solo los archivos que la tarea pide.
- Antes de implementar, mostrá un plan corto y esperá mi aprobación.
- Después de implementar, explicame el diff en lenguaje simple.
- No hagas commit sin mi OK. Mensajes en Conventional Commits.
- Nunca leas, imprimas ni subas credenciales ni archivos .env reales.
- Si algo puede haber cambiado en versiones recientes de una herramienta,
  avisame y no lo des por seguro.
- Si mi pedido tiene un problema de diseño, decímelo en vez de obedecer.

## Stack y convenciones
- Python (comentarios breves) y SQL. Configuración por variables de entorno.
- Docker Compose para todo lo que corra local. Máquina: 16 GB de RAM.
- Nombres de archivo descriptivos en snake_case (Python/SQL). Los nombres
  convencionales (README.md, .gitignore, docker-compose.yml, .env.example)
  no se cambian.
- Decisiones importantes como ADR cortos en docs/adr/
  (contexto, decisión, consecuencias).

## Estado actual
Ver el checklist en docs/ROADMAP.md.
