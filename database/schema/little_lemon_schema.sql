-- MySQL dump 10.13  Distrib 8.4.13, for Linux (x86_64)
--
-- Host: localhost    Database: little_lemon_restaurante
-- ------------------------------------------------------
-- Server version	8.4.13-0ubuntu0.26.04.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `little_lemon_restaurante`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `little_lemon_restaurante` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `little_lemon_restaurante`;

--
-- Table structure for table `Cuisines`
--

DROP TABLE IF EXISTS `Cuisines`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Cuisines` (
  `Cuisine` varchar(50) NOT NULL,
  `Description` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`Cuisine`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Customers`
--

DROP TABLE IF EXISTS `Customers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Customers` (
  `CustomerID` int NOT NULL AUTO_INCREMENT,
  `FullName` varchar(120) NOT NULL,
  `ContactNumber` varchar(30) DEFAULT NULL,
  `Email` varchar(150) NOT NULL,
  PRIMARY KEY (`CustomerID`),
  UNIQUE KEY `Email` (`Email`)
) ENGINE=InnoDB AUTO_INCREMENT=101 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `DeliveryStatuses`
--

DROP TABLE IF EXISTS `DeliveryStatuses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DeliveryStatuses` (
  `DeliveryStatusID` int NOT NULL AUTO_INCREMENT,
  `StatusName` varchar(60) NOT NULL,
  PRIMARY KEY (`DeliveryStatusID`),
  UNIQUE KEY `StatusName` (`StatusName`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `MenuCategories`
--

DROP TABLE IF EXISTS `MenuCategories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `MenuCategories` (
  `CategoryID` int NOT NULL AUTO_INCREMENT,
  `CategoryName` varchar(50) NOT NULL,
  PRIMARY KEY (`CategoryID`),
  UNIQUE KEY `CategoryName` (`CategoryName`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `MenuItems`
--

DROP TABLE IF EXISTS `MenuItems`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `MenuItems` (
  `MenuItemsID` int NOT NULL AUTO_INCREMENT,
  `CourseName` varchar(100) NOT NULL,
  `StarterName` varchar(100) NOT NULL,
  `DesertName` varchar(100) NOT NULL,
  `DrinkName` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`MenuItemsID`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `MenuProducts`
--

DROP TABLE IF EXISTS `MenuProducts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `MenuProducts` (
  `ProductID` int NOT NULL AUTO_INCREMENT,
  `ProductName` varchar(100) NOT NULL,
  `CategoryID` int NOT NULL,
  `Cuisine` varchar(50) NOT NULL,
  `Price` decimal(10,2) NOT NULL,
  `Description` varchar(250) DEFAULT NULL,
  PRIMARY KEY (`ProductID`),
  UNIQUE KEY `uq_product_cuisine` (`ProductName`,`Cuisine`),
  KEY `fk_product_category` (`CategoryID`),
  KEY `fk_product_cuisine` (`Cuisine`),
  CONSTRAINT `fk_product_category` FOREIGN KEY (`CategoryID`) REFERENCES `MenuCategories` (`CategoryID`),
  CONSTRAINT `fk_product_cuisine` FOREIGN KEY (`Cuisine`) REFERENCES `Cuisines` (`Cuisine`),
  CONSTRAINT `MenuProducts_chk_1` CHECK ((`Price` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Menus`
--

DROP TABLE IF EXISTS `Menus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Menus` (
  `MenuID` int NOT NULL AUTO_INCREMENT,
  `MenuItemsID` int NOT NULL,
  `MenuName` varchar(100) NOT NULL,
  `Cuisine` varchar(50) NOT NULL,
  PRIMARY KEY (`MenuID`),
  UNIQUE KEY `MenuName` (`MenuName`),
  KEY `fk_menu_items` (`MenuItemsID`),
  KEY `fk_menu_cuisine` (`Cuisine`),
  CONSTRAINT `fk_menu_cuisine` FOREIGN KEY (`Cuisine`) REFERENCES `Cuisines` (`Cuisine`),
  CONSTRAINT `fk_menu_items` FOREIGN KEY (`MenuItemsID`) REFERENCES `MenuItems` (`MenuItemsID`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `OrderDeliveryHistory`
--

DROP TABLE IF EXISTS `OrderDeliveryHistory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `OrderDeliveryHistory` (
  `HistoryID` int NOT NULL AUTO_INCREMENT,
  `OrderID` int NOT NULL,
  `DeliveryStatusID` int NOT NULL,
  `StatusDate` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Notes` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`HistoryID`),
  KEY `fk_history_status` (`DeliveryStatusID`),
  KEY `idx_history_order_date` (`OrderID`,`StatusDate`),
  CONSTRAINT `fk_history_order` FOREIGN KEY (`OrderID`) REFERENCES `Orders` (`OrderID`) ON DELETE CASCADE,
  CONSTRAINT `fk_history_status` FOREIGN KEY (`DeliveryStatusID`) REFERENCES `DeliveryStatuses` (`DeliveryStatusID`)
) ENGINE=InnoDB AUTO_INCREMENT=843 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `OrderDetails`
--

DROP TABLE IF EXISTS `OrderDetails`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `OrderDetails` (
  `OrderDetailID` int NOT NULL AUTO_INCREMENT,
  `OrderID` int NOT NULL,
  `ProductID` int NOT NULL,
  `Quantity` int unsigned NOT NULL,
  `UnitPrice` decimal(10,2) NOT NULL,
  PRIMARY KEY (`OrderDetailID`),
  KEY `fk_detail_order` (`OrderID`),
  KEY `fk_detail_product` (`ProductID`),
  CONSTRAINT `fk_detail_order` FOREIGN KEY (`OrderID`) REFERENCES `Orders` (`OrderID`) ON DELETE CASCADE,
  CONSTRAINT `fk_detail_product` FOREIGN KEY (`ProductID`) REFERENCES `MenuProducts` (`ProductID`),
  CONSTRAINT `OrderDetails_chk_1` CHECK ((`Quantity` > 0)),
  CONSTRAINT `OrderDetails_chk_2` CHECK ((`UnitPrice` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=681 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`jeremias`@`localhost`*/ /*!50003 TRIGGER `trg_orderdetails_ai` AFTER INSERT ON `OrderDetails` FOR EACH ROW BEGIN
    UPDATE Orders
       SET Quantity = Quantity + NEW.Quantity,
           TotalCost = TotalCost + (NEW.Quantity * NEW.UnitPrice)
     WHERE OrderID = NEW.OrderID;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`jeremias`@`localhost`*/ /*!50003 TRIGGER `trg_orderdetails_au` AFTER UPDATE ON `OrderDetails` FOR EACH ROW BEGIN
    IF NEW.OrderID = OLD.OrderID THEN
        UPDATE Orders
           SET Quantity = Quantity - OLD.Quantity + NEW.Quantity,
               TotalCost = TotalCost - (OLD.Quantity * OLD.UnitPrice)
                           + (NEW.Quantity * NEW.UnitPrice)
         WHERE OrderID = NEW.OrderID;
    ELSE
        UPDATE Orders
           SET Quantity = Quantity - OLD.Quantity,
               TotalCost = TotalCost - (OLD.Quantity * OLD.UnitPrice)
         WHERE OrderID = OLD.OrderID;
        UPDATE Orders
           SET Quantity = Quantity + NEW.Quantity,
               TotalCost = TotalCost + (NEW.Quantity * NEW.UnitPrice)
         WHERE OrderID = NEW.OrderID;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`jeremias`@`localhost`*/ /*!50003 TRIGGER `trg_orderdetails_ad` AFTER DELETE ON `OrderDetails` FOR EACH ROW BEGIN
    UPDATE Orders
       SET Quantity = Quantity - OLD.Quantity,
           TotalCost = TotalCost - (OLD.Quantity * OLD.UnitPrice)
     WHERE OrderID = OLD.OrderID;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `Orders`
--

DROP TABLE IF EXISTS `Orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Orders` (
  `OrderID` int NOT NULL AUTO_INCREMENT,
  `MenuID` int NOT NULL,
  `CustomerID` int NOT NULL,
  `ReservationID` int DEFAULT NULL,
  `StaffID` int DEFAULT NULL,
  `OrderDate` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Quantity` int unsigned NOT NULL DEFAULT '0',
  `TotalCost` decimal(12,2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`OrderID`),
  KEY `fk_orders_menu` (`MenuID`),
  KEY `fk_orders_reservation` (`ReservationID`),
  KEY `fk_orders_staff` (`StaffID`),
  KEY `idx_orders_customer_date` (`CustomerID`,`OrderDate`),
  CONSTRAINT `fk_orders_customer` FOREIGN KEY (`CustomerID`) REFERENCES `Customers` (`CustomerID`),
  CONSTRAINT `fk_orders_menu` FOREIGN KEY (`MenuID`) REFERENCES `Menus` (`MenuID`),
  CONSTRAINT `fk_orders_reservation` FOREIGN KEY (`ReservationID`) REFERENCES `Reservations` (`ReservationID`),
  CONSTRAINT `fk_orders_staff` FOREIGN KEY (`StaffID`) REFERENCES `Staff` (`StaffID`),
  CONSTRAINT `Orders_chk_1` CHECK ((`TotalCost` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=241 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Reservations`
--

DROP TABLE IF EXISTS `Reservations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Reservations` (
  `ReservationID` int NOT NULL AUTO_INCREMENT,
  `CustomerID` int NOT NULL,
  `TableNumber` int NOT NULL,
  `ReservationDate` datetime NOT NULL,
  `PartySize` tinyint unsigned NOT NULL,
  `ReservationStatus` enum('Confirmada','Cancelada','Completada') NOT NULL DEFAULT 'Confirmada',
  PRIMARY KEY (`ReservationID`),
  KEY `fk_reservations_customer` (`CustomerID`),
  KEY `idx_reservations_table_date` (`TableNumber`,`ReservationDate`),
  CONSTRAINT `fk_reservations_customer` FOREIGN KEY (`CustomerID`) REFERENCES `Customers` (`CustomerID`),
  CONSTRAINT `fk_reservations_table` FOREIGN KEY (`TableNumber`) REFERENCES `RestaurantTables` (`TableNumber`),
  CONSTRAINT `Reservations_chk_1` CHECK ((`PartySize` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=1003 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `RestaurantTables`
--

DROP TABLE IF EXISTS `RestaurantTables`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `RestaurantTables` (
  `TableNumber` int NOT NULL,
  `Capacity` tinyint unsigned NOT NULL,
  PRIMARY KEY (`TableNumber`),
  CONSTRAINT `RestaurantTables_chk_1` CHECK ((`Capacity` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Staff`
--

DROP TABLE IF EXISTS `Staff`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Staff` (
  `StaffID` int NOT NULL AUTO_INCREMENT,
  `FullName` varchar(120) NOT NULL,
  `RoleID` int NOT NULL,
  `Salary` decimal(12,2) NOT NULL,
  `Email` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`StaffID`),
  UNIQUE KEY `Email` (`Email`),
  KEY `fk_staff_role` (`RoleID`),
  CONSTRAINT `fk_staff_role` FOREIGN KEY (`RoleID`) REFERENCES `StaffRoles` (`RoleID`),
  CONSTRAINT `Staff_chk_1` CHECK ((`Salary` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `StaffRoles`
--

DROP TABLE IF EXISTS `StaffRoles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `StaffRoles` (
  `RoleID` int NOT NULL AUTO_INCREMENT,
  `RoleName` varchar(60) NOT NULL,
  PRIMARY KEY (`RoleID`),
  UNIQUE KEY `RoleName` (`RoleName`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping events for database 'little_lemon_restaurante'
--

--
-- Dumping routines for database 'little_lemon_restaurante'
--
/*!50003 DROP PROCEDURE IF EXISTS `AddBooking` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`jeremias`@`localhost` PROCEDURE `AddBooking`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `CancelBooking` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`jeremias`@`localhost` PROCEDURE `CancelBooking`(
    IN booking_id INT
)
BEGIN
    DELETE FROM Reservations
    WHERE ReservationID = booking_id;

    SELECT CONCAT(
        'Booking ', booking_id,
        ' cancelled'
    ) AS Confirmation;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `CancelOrder` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`jeremias`@`localhost` PROCEDURE `CancelOrder`(IN p_OrderID INT)
BEGIN
    DECLARE v_deleted INT DEFAULT 0;
    START TRANSACTION;
    DELETE FROM Orders WHERE OrderID = p_OrderID;
    SET v_deleted = ROW_COUNT();
    COMMIT;
    SELECT v_deleted AS DeletedOrders;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `CheckBooking` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`jeremias`@`localhost` PROCEDURE `CheckBooking`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `GetMaxQuantity` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`jeremias`@`localhost` PROCEDURE `GetMaxQuantity`()
BEGIN
    SELECT MAX(Quantity) AS MaxQuantity FROM Orders;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `ManageBooking` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`jeremias`@`localhost` PROCEDURE `ManageBooking`(
    IN booking_date DATETIME,
    IN table_number INT
)
BEGIN
    DECLARE booking_count INT DEFAULT 0;

    SELECT COUNT(*)
    INTO booking_count
    FROM Reservations
    WHERE ReservationDate = booking_date
      AND TableNumber = table_number
      AND ReservationStatus = 'Confirmada';

    IF booking_count > 0 THEN
        SELECT CONCAT(
            'Table ', table_number,
            ' is already booked'
        ) AS BookingStatus;
    ELSE
        SELECT CONCAT(
            'Table ', table_number,
            ' is available'
        ) AS BookingStatus;
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `UpdateBooking` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`jeremias`@`localhost` PROCEDURE `UpdateBooking`(
    IN booking_id INT,
    IN booking_date DATETIME
)
BEGIN
    UPDATE Reservations
    SET ReservationDate = booking_date
    WHERE ReservationID = booking_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-14 17:37:11
