# Roadmap (un incremento = un commit chico)

- [x] 0. CLAUDE.md y ROADMAP
- [x] 1. Sacar credenciales del código (.env, .gitignore)
- [x] 2. README básico
- [x] 3. docker-compose con MySQL (schema + datos)
- [x] 4. Script de verificación de conteos (100 / 240 / 680)
- [x] 5. Agregar updated_at y soft delete (ADR-002)
- [x] 6. Generador sintético (2-5 M de filas, semilla fija)
- [x] 7. PostgreSQL + extractor incremental MySQL → raw
- [x] 8. Idempotencia con test
- [x] 9. dbt staging
- [x] 10. dbt marts en estrella + SCD2
- [x] 11. Airflow
- [x] 12. Medición con EXPLAIN ANALYZE
- [x] 13. Dashboard y cierre

## Problemas conocidos del capstone
- ~~Credenciales en Scripts/file1.py~~ (resuelto en PR #2)
- ~~Sin updated_at en ninguna tabla (bloquea la carga incremental)~~ (resuelto en migración 001)
- ~~CancelOrder y CancelBooking hacen DELETE físico~~ (resuelto en migración 001, ver ADR-002)
- Orders.Quantity y TotalCost son desnormalizados (triggers): se mantienen; un test de dbt verifica que coincidan con las líneas
- ~~DEFINER=jeremias@localhost en triggers y procedimientos~~ (se quita al cargar, incremento 3; los dumps quedan intactos)
- Datos personales: Customers.Email/ContactNumber, Staff.Salary: son datos de ejemplo; el salario queda fuera de los marts (ADR-006)
- Orders.MenuID no se relaciona con los productos del pedido (ADR-006)

## Próximos pasos
- CI con GitHub Actions: pytest y dbt build en cada pull request
- Lock file con todas las dependencias (dbt trae ~60 indirectas)
- Usuario de solo lectura en PostgreSQL para el dashboard y alertas de frescura
- Ajustar work_mem para que la deduplicación de staging no ordene en disco
- Una tarea de Airflow por modelo de dbt (por ejemplo, con Cosmos)
- Corregir USE LittleLemonDM en scripts/script1.sql y script2.sql
