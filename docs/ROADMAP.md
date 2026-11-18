# Roadmap (un incremento = un commit chico)

- [x] 0. CLAUDE.md y ROADMAP
- [x] 1. Sacar credenciales del código (.env, .gitignore)
- [x] 2. README básico
- [ ] 3. docker-compose con MySQL (schema + datos)
- [ ] 4. Script de verificación de conteos (100 / 240 / 680)
- [ ] 5. Agregar updated_at y soft delete (ADR-002)
- [ ] 6. Generador sintético (2-5 M de filas, semilla fija)
- [ ] 7. PostgreSQL + extractor incremental MySQL → raw
- [ ] 8. Idempotencia con test
- [ ] 9. dbt staging
- [ ] 10. dbt marts en estrella + SCD2
- [ ] 11. Airflow
- [ ] 12. Medición con EXPLAIN ANALYZE
- [ ] 13. Dashboard y cierre

## Problemas conocidos del capstone
- ~~Credenciales en Scripts/file1.py~~ (resuelto en PR #2)
- Sin updated_at en ninguna tabla (bloquea la carga incremental)
- CancelOrder y CancelBooking hacen DELETE físico
- Orders.Quantity y TotalCost son desnormalizados (triggers)
- DEFINER=jeremias@localhost en triggers y procedimientos
- Datos personales: Customers.Email/ContactNumber, Staff.Salary