# Little Lemon: from database capstone to ELT pipeline

This repo started as my database engineering capstone: a MySQL 8.4
operational database for **Little Lemon**, a fictional restaurant that takes
orders, deliveries and table bookings.

I am turning it, in small increments, into a data engineering portfolio
project: **MySQL (OLTP) → PostgreSQL (raw / staging / marts) with dbt,
orchestrated by Airflow**.

> **Current status:** only the MySQL capstone exists today. The pipeline is
> planned, not built yet. Progress is tracked in [docs/ROADMAP.md](docs/ROADMAP.md).

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

## Repository layout

```
database/
  schema/            Full schema dump: tables, triggers and procedures
  sample-data/       Data dump (INSERTs only)
  procedures/        Stored procedures on their own (also in the schema dump)
scripts/
  explore_database.py  Python example: connects to MySQL and runs a few queries
  verify_load.py     Checks row counts and order totals after loading
  script1-4.sql      Capstone exercises: views, procedures, prepared statements
data/                Original course data (.xlsx)
models/              MySQL Workbench model (.mwb)
tableau/             Tableau workbook (.twbx)
screenshots/         ER diagram
docker/              Container setup (MySQL init script)
docs/                Roadmap and, later, architecture decisions (ADRs)
docker-compose.yml   Local MySQL 8.4 loaded with schema and data
```

## Running it locally

**Requirements:** Docker with Compose, and Python 3.

1. Configure the connection. Copy the template and fill in your own user and
   passwords. `.env` is git-ignored.

   ```bash
   cp .env.example .env
   ```

2. Start MySQL. On the first start it loads the schema and the data
   automatically (`docker/mysql/initdb/01-load-capstone-dump.sh`), and it is ready when the
   container shows as `healthy`:

   ```bash
   docker compose up -d --wait
   ```

   MySQL listens on `127.0.0.1:3307` (not 3306, so it does not clash with a
   local MySQL). The loader strips the `DEFINER=jeremias@localhost` clauses
   from the schema dump, so triggers and procedures belong to the user that
   creates them.

   The load only runs when the data volume is empty. To reload from scratch
   (for example after changing the dumps), delete the volume:

   ```bash
   docker compose down -v
   ```

3. Install the driver and run the example script:

   ```bash
   python3 -m venv .venv
   .venv/bin/pip install mysql-connector-python
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

   The expected counts are those of the sample data (100 customers,
   240 orders, 680 order lines, …).

## Known limitations

- `scripts/script1.sql` and `scripts/script2.sql` use `USE LittleLemonDM`,
  but the database is now called `little_lemon_restaurante`, so they fail as
  they are.
- There is no `requirements.txt` yet.
- The data contains personal-looking fields (customer emails and phone
  numbers, staff salaries). It comes from the course dataset.
- More capstone issues that the pipeline work will fix are listed in
  [docs/ROADMAP.md](docs/ROADMAP.md#problemas-conocidos-del-capstone).
