USE LittleLemonDM;

CREATE OR REPLACE VIEW OrdersView AS
SELECT
    OrderID,
    Quantity,
    TotalCost
FROM Orders
WHERE Quantity > 2;

SELECT
    c.CustomerID,
    c.CustomerName,
    o.OrderID,
    o.TotalCost,
    m.MenuName,
    mi.ItemName,
    mi.Category
FROM Customers AS c
INNER JOIN Orders AS o
    ON c.CustomerID = o.CustomerID
INNER JOIN Menus AS m
    ON o.MenuID = m.MenuID
INNER JOIN MenuItems AS mi
    ON m.MenuItemsID = mi.MenuItemsID
WHERE o.TotalCost > 150
ORDER BY o.TotalCost ASC;

SELECT MenuName
FROM Menus
WHERE MenuID = ANY (
    SELECT MenuID
    FROM Orders
    WHERE Quantity > 2
);

SELECT MenuName
FROM Menus
WHERE MenuID = ANY (
    SELECT MenuID
    FROM Orders
    WHERE Quantity > 2
);