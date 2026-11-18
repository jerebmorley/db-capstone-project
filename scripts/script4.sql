USE little_lemon_restaurante;

DROP PROCEDURE IF EXISTS AddBooking;

DELIMITER //

CREATE PROCEDURE AddBooking(
    IN booking_id INT,
    IN customer_id INT,
    IN booking_date DATETIME,
    IN table_number INT,
    IN size INT
)
BEGIN
    INSERT INTO Reservations (
        ReservationID,
        CustomerID,
        ReservationDate,
        TableNumber,
        PartySize,
        ReservationStatus
    )
    VALUES (
        booking_id,
        customer_id,
        booking_date,
        table_number,
        size,
        'Confirmada'
    );
END //

DELIMITER ;

CALL AddBooking(
    1002,
    1,
    '2026-11-20 20:00:00',
    5,
    6
);

select *
from Reservations
where ReservationID = 1001;

DROP PROCEDURE IF EXISTS UpdateBooking;

DELIMITER //

CREATE PROCEDURE UpdateBooking(
    IN booking_id INT,
    IN booking_date DATETIME
)
BEGIN
    UPDATE Reservations
    SET ReservationDate = booking_date
    WHERE ReservationID = booking_id;
END //

DELIMITER ;

CALL UpdateBooking(
    1001,
    '2026-11-25 21:00:00'
);

DROP PROCEDURE IF EXISTS CancelBooking;

DELIMITER //

CREATE PROCEDURE CancelBooking(
    IN booking_id INT
)
BEGIN
    DELETE FROM Reservations
    WHERE ReservationID = booking_id;
END //

DELIMITER ;

CALL CancelBooking(1001);

