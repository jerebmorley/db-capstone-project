# Little Lemon: from database capstone to ELT pipeline

This repo started as my database engineering capstone: a MySQL 8.4
operational database for **Little Lemon**, a fictional restaurant that takes
orders, deliveries and table bookings.

I am turning it, in small increments, into a data engineering portfolio
project: **MySQL (OLTP) → PostgreSQL (raw / staging / marts) with dbt,
orchestrated by Airflow**.

> **Current status:** the MySQL source, the extraction into PostgreSQL `raw`
> and the dbt `staging` and `marts` layers work. Airflow is next. Progress is tracked in
> [docs/ROADMAP.md](docs/ROADMAP.md).

```
MySQL (OLTP)  ── scripts/extract_mysql_to_raw.py ──▶  PostgreSQL
little_lemon_restaurante   (incremental, UpdatedAt)    raw.*  (append-only copy)
                                                         │ dbt (dbt/)
                                                         ▼
                                                       staging.*       (latest version, snake_case)
                                                       intermediate.*  (SCD2 versions, order status)
                                                       marts.*         (star schema)
```

## Data model

The database is `little_lemon_restaurante` and has 14 tables:

| Domain | Tables |
|---|---|
| Customers & orders | `Customers`, `Orders`, `OrderDetails`, `OrderDeliveryHistory`, `DeliveryStatuses` |
| Bookings | `Reservations`, `RestaurantTables` |
| Menu | `Menus`, `MenuItems`, `MenuProducts`, `MenuCategories`, `Cuisines` |
| Staff | `Staff`, `StaffRoles` |

It also includes triggers that keep `Orders.Quantity` and `Orders.TotalCost`
in sync with `OrderDetails`, and stored procedures for bookings and orders
(`AddBooking`, `CheckBooking`, `UpdateBooking`, `CancelBooking`,
`ManageBooking`, `CancelOrder`, `GetMaxQuantity`).

![ER diagram](screenshots/final-diagram-er.png)

### Changes since the capstone

The capstone dumps are kept untouched as version 0. Schema changes are
applied on top of them as numbered migrations in `database/migrations/`:

- **001:** every table gets an `UpdatedAt` column that MySQL updates on each
  change (indexed on the 5 transactional tables), so the pipeline can extract
  only what changed. Cancelling no longer deletes rows: `CancelBooking` sets
  the booking to `'Cancelada'`, and `CancelOrder` adds a `'Cancelado'` event
  to `OrderDeliveryHistory`. See
  [ADR-002](docs/adr/002-cancel-by-status-instead-of-delete.md).

## Repository layout

```
database/
  schema/            Capstone schema dump (v0): tables, triggers and procedures
  sample-data/       Capstone data dump (INSERTs only)
  procedures/        Capstone stored procedures (v0, also in the schema dump)
  migrations/        Numbered schema changes applied after the dumps
scripts/
  db_connections.py  MySQL and PostgreSQL connections from environment variables
  extract_mysql_to_raw.py  Incremental extraction MySQL → PostgreSQL raw
  explore_database.py  Python example: connects to MySQL and runs a few queries
  verify_load.py     Checks row counts and order totals after loading
  generate_synthetic_data.py  Adds ~4.4 M reproducible synthetic rows
  script1-4.sql      Capstone exercises: views, procedures, prepared statements
data/                Original course data (.xlsx)
models/              MySQL Workbench model (.mwb)
tableau/             Tableau workbook (.twbx)
screenshots/         ER diagram
dbt/                 dbt project: staging models, tests and macros
docker/              Container setup (MySQL and PostgreSQL init scripts)
docs/                Roadmap and architecture decisions (adr/)
docker-compose.yml   Local MySQL 8.4 (source) and PostgreSQL 18 (warehouse)
requirements.txt     Pinned Python dependencies (requirements-dev.txt adds pytest)
tests/               Integration tests (pytest.ini configures them)
```

## Running it locally

**Requirements:** Docker with Compose, and Python 3.

1. Configure the connection. Copy the template and fill in your own user and
   passwords. `.env` is git-ignored.

   ```bash
   cp .env.example .env
   ```

2. Start MySQL and PostgreSQL. On the first start, MySQL loads the capstone
   dumps (`docker/mysql/initdb/01-load-capstone-dump.sh`) and applies the
   migrations (`02-apply-migrations.sh`), and PostgreSQL creates the `raw`
   and `meta` schemas (`docker/postgres/initdb/01_create_raw_schema.sql`).
   They are ready when both containers show as `healthy`:

   ```bash
   docker compose up -d --wait
   ```

   MySQL listens on `127.0.0.1:3307` and PostgreSQL on `127.0.0.1:5434`, so
   they do not clash with local servers. The MySQL loader strips the `DEFINER=jeremias@localhost` clauses
   from the schema dump, so triggers and procedures belong to the user that
   creates them.

   The load only runs when the data volume is empty. To reload from scratch
   (for example after changing the dumps or adding a migration), delete the
   volume:

   ```bash
   docker compose down -v
   ```

3. Install the dependencies and run the example script:

   ```bash
   python3 -m venv .venv
   .venv/bin/pip install -r requirements.txt
   set -a; source .env; set +a
   .venv/bin/python scripts/explore_database.py
   ```

   If a variable is missing, the script exits with a message listing it.

4. Verify the load. The script checks the row count of all 14 tables and
   that every order's `Quantity` and `TotalCost` match its `OrderDetails`.
   It prints `OK`/`FAIL` per check and exits with code 0 only if all pass:

   ```bash
   .venv/bin/python scripts/verify_load.py
   ```

   The expected counts are those of the sample data right after loading
   (100 customers, 240 orders, 680 order lines, …). Calling `CancelOrder`
   adds a history row, so run it on a fresh load.

5. Optional: generate synthetic data. On a fresh load, this adds customers,
   bookings and orders from 2024-01-01 to 2026-07-31. The same `--seed` and
   `--scale` always produce exactly the same rows
   ([ADR-003](docs/adr/003-synthetic-data-generator.md)):

   ```bash
   .venv/bin/python scripts/generate_synthetic_data.py --seed 42 --scale 1.0
   .venv/bin/python scripts/verify_load.py --expected generated/expected_counts.json
   ```

   With `--scale 1.0` it inserts about 4.4 M rows (50 k customers, 56 k
   bookings, 501 k orders, 1.4 M order lines, 2.3 M status events) in about
   3 minutes, using about 1.3 GB of Docker volume. Use `--scale 0.01` for a
   quick run. The generator refuses to run twice on the same database; to
   start over, recreate it with `docker compose down -v`.

6. Extract MySQL into the PostgreSQL `raw` schema. Each run brings only the
   rows whose `UpdatedAt` changed since the previous one, appends them to
   `raw.<table>` and records the run in `meta.extract_runs`
   ([ADR-004](docs/adr/004-incremental-extraction-to-raw.md)):

   ```bash
   .venv/bin/python scripts/extract_mysql_to_raw.py
   ```

   The first run copies everything (4.4 M rows in about 40 s with the
   synthetic data); a run without changes brings 0 rows. Changes from the
   last 30 seconds wait for the next run (`--lag-seconds`), so transactions
   still in progress are not missed.

7. Build the dbt `staging` layer and run its data tests. Each `stg_*` view
   keeps the latest version of every row in `raw`, with snake_case names
   ([ADR-005](docs/adr/005-dbt-core-staging.md)):

   ```bash
   .venv/bin/dbt build --project-dir dbt --profiles-dir dbt
   ```

   It creates 14 views in the `staging` schema and runs 51 tests (keys,
   relationships, accepted values, order totals and a unit test of the
   deduplication), in about 16 s with the synthetic data. It uses dbt Core
   v1: dbt v2 does not list PostgreSQL among its adapters yet.

   The same command builds the `marts` star schema
   ([ADR-006](docs/adr/006-star-schema-and-scd2-from-raw.md)):

   ```
                       dim_date
                          │
   dim_customers ── fct_orders ──── dim_staff, dim_menus
          │               │
          │        fct_order_lines ── dim_menu_products
          │
          └──── fct_reservations ── dim_restaurant_tables
   ```

   `dim_customers` and `dim_menu_products` are SCD2: one row per version,
   built from the versions kept in `raw`, and every fact points to the
   version that was valid when the event happened. With the synthetic data,
   the full `dbt build` (122 tests) takes about 34 s. Example:

   ```sql
   SELECT d.year, d.quarter, f.channel,
          COUNT(*) AS orders,
          SUM(f.total_cost) FILTER (WHERE NOT f.is_cancelled) AS revenue,
          ROUND(100.0 * AVG(f.is_cancelled::int), 1) AS cancel_pct
   FROM marts.fct_orders f
   JOIN marts.dim_date d USING (date_key)
   GROUP BY 1, 2, 3
   ORDER BY 1, 2, 3;
   ```

## Running the tests

The tests check that the extractor is idempotent
([ADR-004](docs/adr/004-incremental-extraction-to-raw.md)): rerunning it adds
nothing, it only brings changed rows, and if it fails in the middle of a
table nothing is left half-loaded and the retry loads each row exactly once.
Failures are simulated with temporary `CHECK` constraints in PostgreSQL.

```bash
.venv/bin/pip install -r requirements-dev.txt
.venv/bin/pytest -v
```

They run against real MySQL and PostgreSQL in their own Docker project
(`little-lemon-test`, ports 3309 and 5436) built from the fake values in
`.env.example`, which is created at the start and deleted at the end (about
15 s). They never touch your databases or read your `.env`.

## Known limitations

- `scripts/script1.sql` and `scripts/script2.sql` use `USE LittleLemonDM`,
  but the database is now called `little_lemon_restaurante`, so they fail as
  they are.
- The data contains personal-looking fields (customer emails and phone
  numbers, staff salaries). It comes from the course dataset.
- More capstone issues that the pipeline work will fix are listed in
  [docs/ROADMAP.md](docs/ROADMAP.md#problemas-conocidos-del-capstone).
