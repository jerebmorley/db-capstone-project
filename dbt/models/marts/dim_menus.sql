-- Dimensión de menús (SCD1: solo la versión vigente), con su composición.
-- Nota: en el origen Orders.MenuID no se relaciona con los productos del
-- pedido (ver ADR-006); el menú se informa tal cual.

select
    m.menu_id,
    m.menu_name,
    m.cuisine,
    i.starter_name,
    i.course_name,
    i.dessert_name,
    i.drink_name
from {{ ref('stg_menus') }} as m
left join {{ ref('stg_menu_items') }} as i on i.menu_items_id = m.menu_items_id
