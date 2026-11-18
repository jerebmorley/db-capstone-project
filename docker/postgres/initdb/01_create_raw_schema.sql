-- Warehouse de Little Lemon: schema raw (copia fiel de MySQL) y schema meta
-- (control del extractor). Corre solo al crear el volumen de PostgreSQL.
--
-- Convenciones de raw (ver docs/adr/004):
--   * Append-only: cada versión extraída de una fila es una fila nueva.
--   * Columnas con el mismo nombre que en MySQL, en minúscula; sin claves ni
--     NOT NULL, para no rechazar nunca lo que llega del origen.
--   * Tipos: DATETIME -> timestamp, DECIMAL -> numeric, ENUM -> text,
--     INT UNSIGNED -> bigint, TINYINT UNSIGNED -> smallint.
--   * _batch_id y _extracted_at: en qué corrida y cuándo llegó la fila.

CREATE SCHEMA raw;
CREATE SCHEMA meta;

CREATE TABLE raw.cuisines (
    cuisine          varchar(50),
    description      varchar(200),
    updatedat        timestamp(6),
    _batch_id        bigint NOT NULL,
    _extracted_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE raw.customers (
    customerid       integer,
    fullname         varchar(120),
    contactnumber    varchar(30),
    email            varchar(150),
    updatedat        timestamp(6),
    _batch_id        bigint NOT NULL,
    _extracted_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE raw.deliverystatuses (
    deliverystatusid integer,
    statusname       varchar(60),
    updatedat        timestamp(6),
    _batch_id        bigint NOT NULL,
    _extracted_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE raw.menucategories (
    categoryid       integer,
    categoryname     varchar(50),
    updatedat        timestamp(6),
    _batch_id        bigint NOT NULL,
    _extracted_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE raw.menuitems (
    menuitemsid      integer,
    coursename       varchar(100),
    startername      varchar(100),
    desertname       varchar(100),
    drinkname        varchar(100),
    updatedat        timestamp(6),
    _batch_id        bigint NOT NULL,
    _extracted_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE raw.menuproducts (
    productid        integer,
    productname      varchar(100),
    categoryid       integer,
    cuisine          varchar(50),
    price            numeric(10,2),
    description      varchar(250),
    updatedat        timestamp(6),
    _batch_id        bigint NOT NULL,
    _extracted_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE raw.menus (
    menuid           integer,
    menuitemsid      integer,
    menuname         varchar(100),
    cuisine          varchar(50),
    updatedat        timestamp(6),
    _batch_id        bigint NOT NULL,
    _extracted_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE raw.orderdeliveryhistory (
    historyid        integer,
    orderid          integer,
    deliverystatusid integer,
    statusdate       timestamp(0),
    notes            varchar(200),
    updatedat        timestamp(6),
    _batch_id        bigint NOT NULL,
    _extracted_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE raw.orderdetails (
    orderdetailid    integer,
    orderid          integer,
    productid        integer,
    quantity         bigint,
    unitprice        numeric(10,2),
    updatedat        timestamp(6),
    _batch_id        bigint NOT NULL,
    _extracted_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE raw.orders (
    orderid          integer,
    menuid           integer,
    customerid       integer,
    reservationid    integer,
    staffid          integer,
    orderdate        timestamp(0),
    quantity         bigint,
    totalcost        numeric(12,2),
    updatedat        timestamp(6),
    _batch_id        bigint NOT NULL,
    _extracted_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE raw.reservations (
    reservationid    integer,
    customerid       integer,
    tablenumber      integer,
    reservationdate  timestamp(0),
    partysize        smallint,
    reservationstatus text,
    updatedat        timestamp(6),
    _batch_id        bigint NOT NULL,
    _extracted_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE raw.restauranttables (
    tablenumber      integer,
    capacity         smallint,
    updatedat        timestamp(6),
    _batch_id        bigint NOT NULL,
    _extracted_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE raw.staff (
    staffid          integer,
    fullname         varchar(120),
    roleid           integer,
    salary           numeric(12,2),
    email            varchar(150),
    updatedat        timestamp(6),
    _batch_id        bigint NOT NULL,
    _extracted_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE raw.staffroles (
    roleid           integer,
    rolename         varchar(60),
    updatedat        timestamp(6),
    _batch_id        bigint NOT NULL,
    _extracted_at    timestamptz NOT NULL DEFAULT now()
);

-- Hasta qué UpdatedAt (inclusive) se extrajo cada tabla de MySQL.
CREATE TABLE meta.watermarks (
    table_name       text PRIMARY KEY,
    high_watermark   timestamp(6) NOT NULL,
    updated_at       timestamptz NOT NULL DEFAULT now()
);

-- Una corrida del extractor = un batch_id; una fila por tabla procesada.
CREATE SEQUENCE meta.batch_id_seq;

CREATE TABLE meta.extract_runs (
    batch_id         bigint NOT NULL,
    table_name       text NOT NULL,
    window_from      timestamp(6) NOT NULL,
    window_to        timestamp(6) NOT NULL,
    rows_loaded      bigint NOT NULL,
    started_at       timestamptz NOT NULL,
    finished_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (batch_id, table_name)
);
