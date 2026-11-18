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
  file1.py           Python example: connects to MySQL and runs a few queries
  script1-4.sql      Capstone exercises: views, procedures, prepared statements
data/                Original course data (.xlsx)
models/              MySQL Workbench model (.mwb)
tableau/             Tableau workbook (.twbx)
screenshots/         ER diagram
docs/                Roadmap and, later, architecture decisions (ADRs)
```

## Running it locally (temporary)

These are manual steps until increment 3 adds Docker Compose.

**Requirements:** MySQL 8.4 and Python 3.

1. Load the schema, then the data. The schema dump has
   `DEFINER=jeremias@localhost` on its triggers and procedures, which fails
   if that user does not exist on your server, so strip it while loading:

   ```bash
   sed -E 's/DEFINER=`[^`]+`@`[^`]+`//g' database/schema/little_lemon_schema.sql | mysql -u <your_user> -p
   mysql -u <your_user> -p little_lemon_restaurante < database/sample-data/little_lemon_data.sql
   ```

2. Configure the connection. Copy the template and fill in your values
   (set `DB_NAME=little_lemon_restaurante`). `.env` is git-ignored.

   ```bash
   cp .env.example .env
   ```

3. Install the driver and run the example script:

   ```bash
   python3 -m venv .venv
   .venv/bin/pip install mysql-connector-python
   set -a; source .env; set +a
   .venv/bin/python scripts/file1.py
   ```

   If a variable is missing, the script exits with a message listing it.

## Known limitations

- `scripts/script1.sql` and `scripts/script2.sql` use `USE LittleLemonDM`,
  but the database is now called `little_lemon_restaurante`, so they fail as
  they are.
- There is no `requirements.txt` yet.
- The data contains personal-looking fields (customer emails and phone
  numbers, staff salaries). It comes from the course dataset.
- More capstone issues that the pipeline work will fix are listed in
  [docs/ROADMAP.md](docs/ROADMAP.md#problemas-conocidos-del-capstone).
