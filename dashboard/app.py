"""Dashboard de Little Lemon sobre los marts del warehouse.

Solo lee el schema marts (y la fecha de la última extracción de meta). Las
consultas son las del benchmark (docs/performance.md), con los filtros como
parámetros.

Uso local:
    set -a; source .env; set +a
    .venv/bin/streamlit run dashboard/app.py
Con Docker:
    docker compose --profile dashboard up -d --build
"""

import sys
from pathlib import Path

import altair as alt
import pandas as pd
import streamlit as st

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from db_connections import conectar_postgres  # noqa: E402

CANALES = {"dine_in": "Dine-in", "delivery": "Delivery"}
COLORES = alt.Scale(domain=list(CANALES.values()), range=["#2f6f4f", "#e0a422"])

st.set_page_config(page_title="Little Lemon", page_icon="🍋", layout="wide")


@st.cache_data(ttl=600, show_spinner=False)
def consultar(sql, params=()):
    """Corre una consulta y devuelve un DataFrame. Se cachea 10 minutos."""
    try:
        with conectar_postgres() as pg:
            cursor = pg.execute(sql, params)
            columnas = [c.name for c in cursor.description]
            return pd.DataFrame(cursor.fetchall(), columns=columnas)
    except SystemExit as error:  # faltan variables PG_*
        st.error(str(error))
        st.stop()


def dinero(valor):
    """$76.8M en vez de $76,843,166: entra en la tarjeta del KPI."""
    for limite, sufijo in ((1e6, "M"), (1e3, "k")):
        if abs(valor) >= limite:
            return f"${valor / limite:,.1f}{sufijo}"
    return f"${valor:,.0f}"


def con_etiqueta_de_canal(df):
    df = df.copy()
    df["channel"] = df["channel"].map(CANALES)
    return df


# --- Filtros ---------------------------------------------------------------

limites = consultar("SELECT min(date_day) AS desde, max(date_day) AS hasta FROM marts.dim_date")
primero, ultimo = limites.iloc[0]["desde"], limites.iloc[0]["hasta"]

# Rango por defecto: los meses "completos", con al menos la mitad de los pedidos
# de un mes típico. Deja afuera los meses de muestra (ago-sep 2026, 240 pedidos)
# y los que solo tienen reservas, que en el gráfico parecían una caída a cero.
completos = consultar(
    """
    WITH mensual AS (
        SELECT date_trunc('month', ordered_at)::date AS mes, COUNT(*) AS pedidos
        FROM marts.fct_orders GROUP BY 1
    )
    SELECT min(mes) AS desde, (max(mes) + interval '1 month - 1 day')::date AS hasta
    FROM mensual
    WHERE pedidos >= 0.5 * (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY pedidos) FROM mensual)
    """
).iloc[0]
desde_defecto = completos["desde"] if pd.notna(completos["desde"]) else primero
hasta_defecto = completos["hasta"] if pd.notna(completos["hasta"]) else ultimo

st.title("🍋 Little Lemon")
frescura = consultar("SELECT max(finished_at) AS ultima FROM meta.extract_runs")
ultima = frescura.iloc[0]["ultima"]
st.caption(
    "Orders, revenue and bookings from the `marts` star schema. "
    + (f"Data extracted up to {ultima:%Y-%m-%d %H:%M} UTC." if ultima is not None else "No extraction yet.")
)

with st.sidebar:
    st.header("Filters")
    rango = st.date_input(
        "Order date", value=(desde_defecto, hasta_defecto), min_value=primero, max_value=ultimo
    )
    st.caption("By default, only complete months. Earlier and later dates are selectable.")
    canales = st.multiselect(
        "Channel", options=list(CANALES), default=list(CANALES), format_func=CANALES.get
    )

if not isinstance(rango, tuple) or len(rango) != 2 or not canales:
    st.info("Pick a start date, an end date and at least one channel.")
    st.stop()

desde, hasta = (int(f"{d:%Y%m%d}") for d in rango)
filtro = (desde, hasta, canales)
DONDE = "f.date_key BETWEEN %s AND %s AND f.channel = ANY(%s)"

# --- KPIs ------------------------------------------------------------------

kpis = consultar(
    f"""
    SELECT
        COUNT(*)                                                         AS orders,
        COALESCE(SUM(f.total_cost) FILTER (WHERE NOT f.is_cancelled), 0)::float8 AS revenue,
        AVG(f.is_cancelled::int)::float8                                AS cancel_rate,
        AVG(f.minutes_to_complete) FILTER (WHERE NOT f.is_cancelled)::float8 AS avg_minutes
    FROM marts.fct_orders AS f
    WHERE {DONDE}
    """,
    filtro,
).iloc[0]

c1, c2, c3, c4 = st.columns(4)
c1.metric("Revenue (not cancelled)", dinero(kpis["revenue"]))
c2.metric("Orders", f"{int(kpis['orders']):,}")
c3.metric("Cancelled", f"{(kpis['cancel_rate'] or 0):.1%}")
c4.metric("Avg. minutes to complete", f"{kpis['avg_minutes']:.0f}" if pd.notna(kpis["avg_minutes"]) else "–")

# --- Tendencia mensual -----------------------------------------------------

mensual = con_etiqueta_de_canal(consultar(
    f"""
    SELECT date_trunc('month', f.ordered_at)::date AS month, f.channel,
           SUM(f.total_cost) FILTER (WHERE NOT f.is_cancelled)::float8 AS revenue
    FROM marts.fct_orders AS f
    WHERE {DONDE}
    GROUP BY 1, 2
    ORDER BY 1
    """,
    filtro,
))
st.subheader("Monthly revenue by channel")
st.altair_chart(
    alt.Chart(mensual).mark_line(point=True).encode(
        x=alt.X("month:T", title=None),
        y=alt.Y("revenue:Q", title="Revenue ($)"),
        color=alt.Color("channel:N", scale=COLORES, title="Channel"),
        tooltip=["month:T", "channel:N", alt.Tooltip("revenue:Q", format=",.0f")],
    ),
    use_container_width=True,
)

izquierda, derecha = st.columns(2)

# --- Productos -------------------------------------------------------------

productos = consultar(
    f"""
    SELECT p.product_name, p.category_name, SUM(l.line_total)::float8 AS revenue
    FROM marts.fct_order_lines AS l
    JOIN marts.fct_orders AS f ON f.order_id = l.order_id
    JOIN marts.dim_menu_products AS p ON p.product_key = l.product_key
    WHERE {DONDE} AND NOT f.is_cancelled
    GROUP BY 1, 2
    ORDER BY revenue DESC
    LIMIT 10
    """,
    filtro,
)
with izquierda:
    st.subheader("Top 10 products by revenue")
    st.altair_chart(
        alt.Chart(productos).mark_bar().encode(
            x=alt.X("revenue:Q", title="Revenue ($)"),
            y=alt.Y("product_name:N", sort="-x", title=None),
            color=alt.Color("category_name:N", title="Category"),
            tooltip=["product_name:N", "category_name:N", alt.Tooltip("revenue:Q", format=",.0f")],
        ),
        use_container_width=True,
    )

# --- Cancelaciones por hora ------------------------------------------------

por_hora = con_etiqueta_de_canal(consultar(
    f"""
    SELECT extract(hour FROM f.ordered_at)::int AS hour, f.channel,
           COUNT(*) AS orders, AVG(f.is_cancelled::int)::float8 AS cancel_rate
    FROM marts.fct_orders AS f
    WHERE {DONDE}
    GROUP BY 1, 2
    ORDER BY 1
    """,
    filtro,
))
with derecha:
    st.subheader("Cancellation rate by hour of the day")
    st.altair_chart(
        alt.Chart(por_hora).mark_bar().encode(
            x=alt.X("hour:O", title="Hour"),
            xOffset="channel:N",
            y=alt.Y("cancel_rate:Q", title="Cancelled", axis=alt.Axis(format="%")),
            color=alt.Color("channel:N", scale=COLORES, title="Channel"),
            tooltip=["hour:O", "channel:N", "orders:Q", alt.Tooltip("cancel_rate:Q", format=".1%")],
        ),
        use_container_width=True,
    )

izquierda, derecha = st.columns(2)

# --- Ocupación del salón ---------------------------------------------------

ocupacion = consultar(
    """
    SELECT d.day_of_week, d.day_name,
           COUNT(*) AS bookings,
           AVG(r.seat_utilization)::float8 AS utilization,
           AVG(r.is_cancelled::int)::float8 AS cancel_rate
    FROM marts.fct_reservations AS r
    JOIN marts.dim_date AS d ON d.date_key = r.date_key
    WHERE r.date_key BETWEEN %s AND %s
    GROUP BY 1, 2
    ORDER BY 1
    """,
    (desde, hasta),
)
with izquierda:
    st.subheader("Table utilization by weekday")
    st.caption("Bookings only (dine-in): party size / table capacity. Ignores the channel filter.")
    st.altair_chart(
        alt.Chart(ocupacion).mark_bar(color="#2f6f4f").encode(
            x=alt.X("day_name:N", sort=alt.SortField("day_of_week"), title=None),
            y=alt.Y("utilization:Q", title="Avg. seat utilization", axis=alt.Axis(format="%")),
            tooltip=["day_name:N", "bookings:Q", alt.Tooltip("utilization:Q", format=".0%"),
                     alt.Tooltip("cancel_rate:Q", title="cancelled", format=".1%")],
        ),
        use_container_width=True,
    )

# --- Frecuencia de clientes ------------------------------------------------

frecuencia = consultar(
    f"""
    WITH per_customer AS (
        SELECT f.customer_id, COUNT(*) AS orders
        FROM marts.fct_orders AS f
        WHERE {DONDE} AND NOT f.is_cancelled
        GROUP BY 1
    )
    SELECT LEAST(orders, 20) AS orders, COUNT(*) AS customers
    FROM per_customer
    GROUP BY 1
    ORDER BY 1
    """,
    filtro,
)
with derecha:
    st.subheader("Customers by number of orders")
    st.caption("Orders not cancelled in the period; 20 means 20 or more.")
    st.altair_chart(
        alt.Chart(frecuencia).mark_bar(color="#e0a422").encode(
            x=alt.X("orders:O", title="Orders per customer"),
            y=alt.Y("customers:Q", title="Customers"),
            tooltip=["orders:O", "customers:Q"],
        ),
        use_container_width=True,
    )
