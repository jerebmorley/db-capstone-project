USE little_lemon_restaurante;

DELIMITER //

CREATE PROCEDURE CheckBooking(
    IN booking_date DATE,
    IN table_number INT
)
BEGIN
    DECLARE booking_status VARCHAR(50);

    SELECT IF(COUNT(*) > 0, 'Booked', 'Available')
    INTO booking_status
    FROM Reservations
    WHERE DATE(ReservationDate) = booking_date
      AND TableNumber = table_number
      AND ReservationStatus = 'Confirmada';

    SELECT
        CONCAT(
            'Table ', table_number,
            ' is ', booking_status
        ) AS BookingStatus;
END //

DELIMITER ;

CALL CheckBooking('2026-11-15', 5);


DROP PROCEDURE IF EXISTS AddValidBooking;

DELIMITER //

CREATE PROCEDURE AddValidBooking(
    IN booking_date DATE,
    IN table_number INT
)
BEGIN
    DECLARE booking_count INT DEFAULT 0;
    DECLARE customer_id INT;
    DECLARE locked_table INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Bloquear la mesa mientras se verifica
    SELECT TableNumber
    INTO locked_table
    FROM RestaurantTables
    WHERE TableNumber = table_number
    FOR UPDATE;

    -- Obtener un cliente existente para la prueba
    SELECT MIN(CustomerID)
    INTO customer_id
    FROM Customers;

    -- Verificar si ya existe una reserva
    SELECT COUNT(*)
    INTO booking_count
    FROM Reservations
    WHERE DATE(ReservationDate) = booking_date
      AND TableNumber = table_number
      AND ReservationStatus = 'Confirmada';

    IF booking_count > 0 THEN

        ROLLBACK;

        SELECT CONCAT(
            'Table ', table_number,
            ' is already booked - booking cancelled'
        ) AS BookingStatus;

    ELSE

        INSERT INTO Reservations (
            CustomerID,
            TableNumber,
            ReservationDate,
            PartySize,
            ReservationStatus
        )
        VALUES (
            customer_id,
            table_number,
            booking_date,
            1,
            'Confirmada'
        );

        COMMIT;

        SELECT CONCAT(
            'Table ', table_number,
            ' booking confirmed'
        ) AS BookingStatus;

    END IF;
END //

DELIMITER ;

CALL AddValidBooking('2026-11-20', 5);
