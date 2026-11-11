
-- =====================================================
-- LITTLE LEMON - ADAPTACION DE BASE DE DATOS
-- Compatible con MySQL 8.4
-- =====================================================

USE LittleLemonDM;

-- =====================================================
-- PASO 1: CREAR TABLA MENUS
-- =====================================================

CREATE TABLE Menus (
    MenuID INT AUTO_INCREMENT PRIMARY KEY,
    MenuItemsID INT NOT NULL,
    MenuName VARCHAR(100) NOT NULL,
    Cuisine VARCHAR(50) NOT NULL,

    CONSTRAINT fk_menus_items
        FOREIGN KEY (MenuItemsID)
        REFERENCES menu_items(id_item)
);

-- =====================================================
-- PASO 2: ADAPTAR LA TABLA PEDIDOS
-- =====================================================

-- Incorporar Quantity y TotalCost,
-- tal como solicita el curso.

ALTER TABLE pedidos
ADD COLUMN Quantity INT NOT NULL DEFAULT 0,
ADD COLUMN TotalCost DECIMAL(10,2) NOT NULL DEFAULT 0.00,
ADD COLUMN MenuID INT NULL;

-- Relacionar pedidos con Menus.

ALTER TABLE pedidos
ADD CONSTRAINT fk_pedidos_menus
FOREIGN KEY (MenuID)
REFERENCES Menus(MenuID);

-- =====================================================
-- PASO 3: ACTUALIZAR LOS TOTALES EXISTENTES
-- =====================================================

-- Recuperamos las cantidades y los costos
-- almacenados en detalle_pedido.

UPDATE pedidos p
LEFT JOIN (
    SELECT
        id_pedido,
        SUM(cantidad) AS total_cantidad,
        SUM(cantidad * precio_unitario) AS total_precio
    FROM detalle_pedido
    GROUP BY id_pedido
) d ON p.id_pedido = d.id_pedido
SET
    p.Quantity = COALESCE(d.total_cantidad, 0),
    p.TotalCost = COALESCE(d.total_precio, 0);

-- =====================================================
-- PASO 4: CREAR VISTA CUSTOMERS
-- =====================================================

CREATE OR REPLACE VIEW Customers AS
SELECT
    id_cliente AS CustomerID,
    CONCAT(nombre, ' ', apellido) AS CustomerName,
    telefono AS ContactNumber,
    email AS Email
FROM clientes;

-- =====================================================
-- PASO 5: CREAR VISTA MENUITEMS
-- =====================================================

-- Recuperamos los nombres y categorias
-- mediante la relacion existente.

CREATE OR REPLACE VIEW MenuItems AS
SELECT
    m.id_item AS MenuItemsID,
    m.nombre AS ItemName,
    c.nombre_categoria AS Category,
    m.precio AS Price
FROM menu_items m
INNER JOIN categorias_menu c
    ON m.id_categoria = c.id_categoria;

-- =====================================================
-- PASO 6: CREAR VISTA ORDERS
-- =====================================================

CREATE OR REPLACE VIEW Orders AS
SELECT
    id_pedido AS OrderID,
    id_cliente AS CustomerID,
    MenuID,
    fecha_pedido AS OrderDate,
    Quantity,
    TotalCost
FROM pedidos;

-- =====================================================
-- PASO 7: DATOS DE PRUEBA
-- =====================================================

-- Clientes

INSERT INTO clientes
(nombre, apellido, telefono, email)
VALUES
('John', 'Smith', '111111111', 'john@example.com'),
('Anna', 'Taylor', '222222222', 'anna@example.com'),
('Mark', 'Wilson', '333333333', 'mark@example.com');

-- Articulos del menu

INSERT INTO menu_items
(nombre, descripcion, precio, id_categoria, id_cocina)
VALUES
('Bruschetta', 'Pan tostado con tomate',
 12.00, 1, 2),

('Pasta Carbonara', 'Pasta italiana',
 25.00, 2, 2),

('Tiramisu', 'Postre italiano',
 10.00, 4, 2),

('Limonada', 'Bebida fresca',
 5.00, 3, NULL);

-- Crear menus utilizando los IDs
-- de los articulos recien insertados.

INSERT INTO Menus
(MenuItemsID, MenuName, Cuisine)
SELECT
    id_item,
    nombre,
    'Italian'
FROM menu_items
WHERE nombre IN (
    'Bruschetta',
    'Pasta Carbonara',
    'Tiramisu'
);

-- Pedidos de prueba

INSERT INTO pedidos
(id_cliente, fecha_pedido, Quantity, TotalCost, MenuID)
SELECT
    c.id_cliente,
    CURRENT_TIMESTAMP,
    2,
    50.00,
    m.MenuID
FROM clientes c
CROSS JOIN Menus m
WHERE c.email = 'john@example.com'
  AND m.MenuName = 'Pasta Carbonara'
LIMIT 1;

INSERT INTO pedidos
(id_cliente, fecha_pedido, Quantity, TotalCost, MenuID)
SELECT
    c.id_cliente,
    CURRENT_TIMESTAMP,
    1,
    12.00,
    m.MenuID
FROM clientes c
CROSS JOIN Menus m
WHERE c.email = 'anna@example.com'
  AND m.MenuName = 'Bruschetta'
LIMIT 1;

-- =====================================================
-- PASO 8: VERIFICAR LAS TABLAS
-- =====================================================

SELECT * FROM Customers;

SELECT * FROM Orders;

SELECT * FROM Menus;

SELECT * FROM MenuItems;

-- =====================================================
-- PASO 9: CREAR UNA TABLA VIRTUAL
-- =====================================================

CREATE OR REPLACE VIEW OrdersView AS
SELECT
    OrderID,
    Quantity,
    TotalCost
FROM Orders
WHERE Quantity > 1;

SELECT * FROM OrdersView;

-- =====================================================
-- PASO 10: CONSULTA CON JOIN
-- =====================================================

SELECT
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.Quantity,
    o.TotalCost
FROM Customers c
INNER JOIN Orders o
    ON c.CustomerID = o.CustomerID;

-- =====================================================
-- PASO 11: JOIN ENTRE CUATRO TABLAS
-- =====================================================

SELECT
    c.CustomerName,
    o.OrderID,
    m.MenuName,
    mi.ItemName,
    mi.Category,
    o.Quantity,
    o.TotalCost
FROM Customers c
INNER JOIN Orders o
    ON c.CustomerID = o.CustomerID
INNER JOIN Menus m
    ON o.MenuID = m.MenuID
INNER JOIN MenuItems mi
    ON m.MenuItemsID = mi.MenuItemsID;

-- =====================================================
-- PASO 12: CONSULTA CON SUBCONSULTA
-- =====================================================

SELECT
    CustomerID,
    CustomerName
FROM Customers
WHERE CustomerID IN (
    SELECT CustomerID
    FROM Orders
    WHERE TotalCost > 20
);

-- =====================================================
-- FIN DE LA ADAPTACION
-- =====================================================
