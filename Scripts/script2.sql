USE LittleLemonDM;

DELIMITER //

CREATE PROCEDURE GetMaxQuantity()
BEGIN
    SELECT MAX(Quantity) AS MaxQuantity
    FROM Orders;
END //

DELIMITER ;

CALL GetMaxQuantity();

PREPARE GetOrderDetail FROM
'SELECT OrderID, Quantity, TotalCost
 FROM Orders
 WHERE CustomerID = ?';

SET @id = 1;

EXECUTE GetOrderDetail USING @id;

DELIMITER //

CREATE PROCEDURE CancelOrder(IN order_id INT)
BEGIN
    DELETE FROM Orders
    WHERE OrderID = order_id;
END //

DELIMITER ;

CALL CancelOrder(5);

