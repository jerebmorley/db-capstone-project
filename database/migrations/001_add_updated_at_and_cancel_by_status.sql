-- Migración 001: UpdatedAt en todas las tablas y cancelación por estado.
-- Ver docs/adr/002-cancel-by-status-instead-of-delete.md

-- 1) UpdatedAt: MySQL lo actualiza solo en cada UPDATE que cambie la fila.
--    Lo usa el extractor incremental (WHERE UpdatedAt > última corrida).
ALTER TABLE Cuisines             ADD COLUMN UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
ALTER TABLE Customers            ADD COLUMN UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
ALTER TABLE DeliveryStatuses     ADD COLUMN UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
ALTER TABLE MenuCategories       ADD COLUMN UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
ALTER TABLE MenuItems            ADD COLUMN UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
ALTER TABLE MenuProducts         ADD COLUMN UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
ALTER TABLE Menus                ADD COLUMN UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
ALTER TABLE OrderDeliveryHistory ADD COLUMN UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
ALTER TABLE OrderDetails         ADD COLUMN UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
ALTER TABLE Orders               ADD COLUMN UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
ALTER TABLE Reservations         ADD COLUMN UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
ALTER TABLE RestaurantTables     ADD COLUMN UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
ALTER TABLE Staff                ADD COLUMN UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);
ALTER TABLE StaffRoles           ADD COLUMN UpdatedAt DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6);

-- 2) Índices en las tablas transaccionales, las que van a crecer a millones
--    de filas: sin índice, el filtro por UpdatedAt recorre toda la tabla.
CREATE INDEX idx_customers_updatedat            ON Customers (UpdatedAt);
CREATE INDEX idx_orders_updatedat               ON Orders (UpdatedAt);
CREATE INDEX idx_orderdetails_updatedat         ON OrderDetails (UpdatedAt);
CREATE INDEX idx_orderdeliveryhistory_updatedat ON OrderDeliveryHistory (UpdatedAt);
CREATE INDEX idx_reservations_updatedat         ON Reservations (UpdatedAt);

-- 3) Cancelar deja de borrar: pasa a ser un cambio de estado.
DROP PROCEDURE IF EXISTS CancelBooking;
DROP PROCEDURE IF EXISTS CancelOrder;

DELIMITER //

-- Solo una reserva Confirmada se puede cancelar.
CREATE PROCEDURE CancelBooking(IN booking_id INT)
BEGIN
    UPDATE Reservations
       SET ReservationStatus = 'Cancelada'
     WHERE ReservationID = booking_id
       AND ReservationStatus = 'Confirmada';

    IF ROW_COUNT() = 1 THEN
        SELECT CONCAT('Booking ', booking_id, ' cancelled') AS Confirmation;
    ELSE
        SELECT CONCAT('Booking ', booking_id, ' not found or not confirmed') AS Confirmation;
    END IF;
END //

-- Registra el evento 'Cancelado' en el historial; el pedido y sus detalles
-- se conservan. No duplica la cancelación si ya estaba cancelado.
CREATE PROCEDURE CancelOrder(IN p_OrderID INT)
BEGIN
    DECLARE v_cancelled INT DEFAULT 0;
    START TRANSACTION;
    INSERT INTO OrderDeliveryHistory (OrderID, DeliveryStatusID, Notes)
    SELECT o.OrderID, ds.DeliveryStatusID, 'Cancelado con CancelOrder'
      FROM Orders o
      JOIN DeliveryStatuses ds ON ds.StatusName = 'Cancelado'
     WHERE o.OrderID = p_OrderID
       AND NOT EXISTS (
           SELECT 1 FROM OrderDeliveryHistory h
            WHERE h.OrderID = o.OrderID
              AND h.DeliveryStatusID = ds.DeliveryStatusID
       );
    SET v_cancelled = ROW_COUNT();
    COMMIT;
    SELECT v_cancelled AS CancelledOrders;
END //

DELIMITER ;
