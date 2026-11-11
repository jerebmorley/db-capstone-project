-- ================================================================
-- LITTLE LEMON / RESTAURANTE - DATOS DEMO AMPLIOS
-- MySQL 8.4 | esquema de la conversacion
-- Ejecutar DESPUES del script de creacion y del de adaptacion.
-- No borra datos existentes; reejecucion sin duplicar registros demo.
-- 120 clientes, 24 empleados, 24 mesas, 48 productos, 48 menus,
-- 90 reservas, 240 pedidos, 600 lineas de pedido aprox. e historial.
-- Datos ficticios. No usar como datos reales de clientes.
-- ================================================================

USE restaurante;

-- Para detectar reejecuciones (sin tocar las tablas originales).
CREATE TABLE IF NOT EXISTS little_lemon_seed_refs (
    entity_type VARCHAR(30) NOT NULL,
    seed_number INT NOT NULL,
    entity_id INT NOT NULL,
    PRIMARY KEY (entity_type, seed_number)
) ENGINE=InnoDB;

DROP PROCEDURE IF EXISTS poblar_little_lemon;
DELIMITER $$
CREATE PROCEDURE poblar_little_lemon()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE j INT DEFAULT 1;
    DECLARE v_id INT;
    DECLARE v_id2 INT;
    DECLARE v_cliente INT;
    DECLARE v_personal INT;
    DECLARE v_reserva INT;
    DECLARE v_menu INT;
    DECLARE v_item INT;
    DECLARE v_categoria INT;
    DECLARE v_cocina INT;
    DECLARE v_estado INT;
    DECLARE v_pedido INT;
    DECLARE v_cantidad INT;
    DECLARE v_lineas INT;
    DECLARE v_total_cantidad INT;
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_fecha DATETIME;
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_cat_nombre VARCHAR(50);
    DECLARE v_coc_nombre VARCHAR(50);
    DECLARE v_mail VARCHAR(100);
    DECLARE v_num_item INT;
    DECLARE v_num_estados INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    DROP TEMPORARY TABLE IF EXISTS ll_seed_menu_def;
    CREATE TEMPORARY TABLE ll_seed_menu_def (
        n INT PRIMARY KEY,
        nombre VARCHAR(100) NOT NULL,
        categoria VARCHAR(50) NOT NULL,
        cocina VARCHAR(50) NOT NULL,
        precio DECIMAL(10,2) NOT NULL
    );
    INSERT INTO ll_seed_menu_def(n,nombre,categoria,cocina,precio) VALUES
    (1,'Empanadas criollas','Entrante','Argentina',9.50),
    (2,'Provoleta','Entrante','Argentina',12.00),
    (3,'Bruschetta clásica','Entrante','Italiana',8.50),
    (4,'Caprese','Entrante','Italiana',10.00),
    (5,'Nachos con guacamole','Entrante','Mexicana',11.00),
    (6,'Quesadillas','Entrante','Mexicana',12.50),
    (7,'Gyozas','Entrante','Japonesa',10.50),
    (8,'Edamame','Entrante','Japonesa',7.00),
    (9,'Hummus con pita','Entrante','Mediterránea',8.00),
    (10,'Falafel','Entrante','Mediterránea',9.00),
    (11,'Sopa de calabaza','Entrante','Internacional',7.50),
    (12,'Ensalada César','Entrante','Internacional',10.50),
    (13,'Bife de chorizo','Plato principal','Argentina',29.00),
    (14,'Milanesa napolitana','Plato principal','Argentina',21.50),
    (15,'Locro','Plato principal','Argentina',19.00),
    (16,'Ravioles de ricota','Plato principal','Italiana',20.00),
    (17,'Lasagna boloñesa','Plato principal','Italiana',23.00),
    (18,'Risotto de hongos','Plato principal','Italiana',22.00),
    (19,'Tacos al pastor','Plato principal','Mexicana',18.50),
    (20,'Burrito de pollo','Plato principal','Mexicana',19.50),
    (21,'Enchiladas verdes','Plato principal','Mexicana',20.50),
    (22,'Ramen shoyu','Plato principal','Japonesa',22.50),
    (23,'Sushi combinado','Plato principal','Japonesa',32.00),
    (24,'Pollo teriyaki','Plato principal','Japonesa',24.00),
    (25,'Shawarma de pollo','Plato principal','Mediterránea',18.00),
    (26,'Moussaka','Plato principal','Mediterránea',23.00),
    (27,'Hamburguesa clásica','Plato principal','Internacional',17.00),
    (28,'Salmón a la plancha','Plato principal','Internacional',30.00),
    (29,'Flan con dulce de leche','Postre','Argentina',7.00),
    (30,'Panqueques con dulce','Postre','Argentina',8.50),
    (31,'Tiramisú','Postre','Italiana',9.00),
    (32,'Panna cotta','Postre','Italiana',8.50),
    (33,'Churros con chocolate','Postre','Mexicana',7.50),
    (34,'Arroz con leche','Postre','Mexicana',6.50),
    (35,'Mochi','Postre','Japonesa',8.00),
    (36,'Dorayaki','Postre','Japonesa',8.50),
    (37,'Baklava','Postre','Mediterránea',9.50),
    (38,'Yogur con miel','Postre','Mediterránea',6.50),
    (39,'Brownie con helado','Postre','Internacional',9.00),
    (40,'Cheesecake frutos rojos','Postre','Internacional',10.00),
    (41,'Agua mineral','Bebida','Internacional',3.00),
    (42,'Limonada','Bebida','Internacional',4.50),
    (43,'Gaseosa cola','Bebida','Internacional',4.00),
    (44,'Jugo de naranja','Bebida','Internacional',5.00),
    (45,'Café espresso','Bebida','Italiana',3.50),
    (46,'Cappuccino','Bebida','Italiana',4.50),
    (47,'Té verde','Bebida','Japonesa',3.50),
    (48,'Licuado de frutilla','Bebida','Internacional',6.00);

    START TRANSACTION;

    -- Catalogos con claves naturales unicas.
    INSERT IGNORE INTO roles (nombre_rol) VALUES
      ('Gerente'), ('Camarero'), ('Cocinero'), ('Repartidor');
    INSERT IGNORE INTO categorias_menu (nombre_categoria) VALUES
      ('Entrante'), ('Plato principal'), ('Bebida'), ('Postre');
    INSERT IGNORE INTO cocinas (nombre_cocina) VALUES
      ('Argentina'), ('Italiana'), ('Mexicana'), ('Japonesa'),
      ('Mediterránea'), ('Internacional');
    INSERT IGNORE INTO estados_entrega (nombre_estado) VALUES
      ('Pendiente'), ('En preparacion'), ('Listo'),
      ('En camino'), ('Entregado'), ('Cancelado');

    -- 120 clientes ficticios con email fijo y unico.
    SET i = 1;
    WHILE i <= 120 DO
        IF NOT EXISTS (SELECT 1 FROM little_lemon_seed_refs
                       WHERE entity_type='cliente' AND seed_number=i) THEN
            SET v_mail = CONCAT('demo.ll.cliente', LPAD(i,3,'0'), '@example.test');
            SET v_id = NULL;
            SELECT id_cliente INTO v_id FROM clientes
            WHERE email = v_mail LIMIT 1;
            IF v_id IS NULL THEN
                INSERT INTO clientes (nombre, apellido, telefono, email)
                VALUES (
                  ELT(1+MOD(i-1,12),'Ana','Luis','María','Carlos','Lucía','Pedro',
                      'Sofía','Mateo','Valentina','Diego','Camila','Julián'),
                  ELT(1+MOD(FLOOR((i-1)/12)+i,12),'Gómez','Pérez','López','Fernández',
                      'Ruiz','Díaz','Torres','Romero','Silva','Acosta','Medina','Castro'),
                  CONCAT('3794', LPAD(i,6,'0')),
                  v_mail
                );
                SET v_id = LAST_INSERT_ID();
            END IF;
            INSERT INTO little_lemon_seed_refs VALUES ('cliente',i,v_id);
        END IF;
        SET i = i+1;
    END WHILE;

    -- 24 empleados. El salario es un ejemplo, no escala real.
    SET i = 1;
    WHILE i <= 24 DO
        IF NOT EXISTS (SELECT 1 FROM little_lemon_seed_refs
                       WHERE entity_type='personal' AND seed_number=i) THEN
            SELECT id_rol INTO v_id2 FROM roles
            WHERE nombre_rol = ELT(1+MOD(i-1,4),
                  'Gerente','Camarero','Cocinero','Repartidor');
            INSERT INTO personal (nombre,apellido,id_rol,salario)
            VALUES (
                ELT(1+MOD(i-1,12),'Martín','Paula','Nicolás','Elena','Tomás','Micaela',
                    'Bruno','Florencia','Agustín','Julieta','Facundo','Carolina'),
                ELT(1+MOD(i-1,8),'Sosa','Benítez','Herrera','Vega',
                    'Rojas','Molina','Aguirre','Farias'),
                v_id2,
                CASE MOD(i-1,4)
                    WHEN 0 THEN 1200000.00
                    WHEN 1 THEN 750000.00
                    WHEN 2 THEN 900000.00
                    ELSE 700000.00 END
            );
            INSERT INTO little_lemon_seed_refs VALUES
                ('personal',i,LAST_INSERT_ID());
        END IF;
        SET i=i+1;
    END WHILE;

    -- Mesas numeros 101..124, reutilizables si ya existen.
    SET i=1;
    WHILE i<=24 DO
        INSERT INTO mesas(numero_mesa,capacidad)
        SELECT 100+i, CASE WHEN MOD(i,5)=0 THEN 8
                           WHEN MOD(i,3)=0 THEN 6
                           WHEN MOD(i,2)=0 THEN 4 ELSE 2 END
        WHERE NOT EXISTS (SELECT 1 FROM mesas WHERE numero_mesa=100+i);
        SET i=i+1;
    END WHILE;

    -- 48 articulos; se usan IDs reales, nunca IDs asumidos.
    SET i=1;
    WHILE i<=48 DO
        IF NOT EXISTS (SELECT 1 FROM little_lemon_seed_refs
                       WHERE entity_type='item' AND seed_number=i) THEN
            SELECT nombre,categoria,cocina,precio
              INTO v_nombre,v_cat_nombre,v_coc_nombre,v_precio
            FROM ll_seed_menu_def WHERE n=i;
            SELECT id_categoria INTO v_categoria FROM categorias_menu
            WHERE nombre_categoria=v_cat_nombre;
            SET v_cocina=NULL;
            IF v_cat_nombre <> 'Bebida' THEN
                SELECT id_cocina INTO v_cocina FROM cocinas
                WHERE nombre_cocina=v_coc_nombre;
            END IF;
            SET v_id=NULL;
            SELECT id_item INTO v_id FROM menu_items
            WHERE nombre=v_nombre LIMIT 1;
            IF v_id IS NULL THEN
                INSERT INTO menu_items(nombre,descripcion,precio,id_categoria,id_cocina)
                VALUES (v_nombre,CONCAT('Especialidad: ',v_nombre),
                        v_precio,v_categoria,v_cocina);
                SET v_id=LAST_INSERT_ID();
            END IF;
            INSERT INTO little_lemon_seed_refs VALUES ('item',i,v_id);
        END IF;
        SET i=i+1;
    END WHILE;

    -- Menus: un registro por articulo para ajustarnos al esquema del curso.
    SET i=1;
    WHILE i<=48 DO
        IF NOT EXISTS (SELECT 1 FROM little_lemon_seed_refs
                       WHERE entity_type='menu' AND seed_number=i) THEN
            SELECT entity_id INTO v_item FROM little_lemon_seed_refs
            WHERE entity_type='item' AND seed_number=i;
            SELECT nombre,cocina INTO v_nombre,v_coc_nombre
            FROM ll_seed_menu_def WHERE n=i;
            SET v_id=NULL;
            SELECT MenuID INTO v_id FROM Menus
            WHERE MenuItemsID=v_item LIMIT 1;
            IF v_id IS NULL THEN
                INSERT INTO Menus (MenuItemsID,MenuName,Cuisine)
                VALUES (v_item,v_nombre,v_coc_nombre);
                SET v_id=LAST_INSERT_ID();
            END IF;
            INSERT INTO little_lemon_seed_refs VALUES ('menu',i,v_id);
        END IF;
        SET i=i+1;
    END WHILE;

    -- 90 reservas de ejemplo distribuidas en varios dias.
    SET i=1;
    WHILE i<=90 DO
        IF NOT EXISTS (SELECT 1 FROM little_lemon_seed_refs
                       WHERE entity_type='reserva' AND seed_number=i) THEN
            SELECT entity_id INTO v_cliente FROM little_lemon_seed_refs
            WHERE entity_type='cliente' AND seed_number=i;
            SET v_fecha=DATE_ADD('2026-10-01 12:00:00',
                                 INTERVAL MOD(i-1,40) DAY);
            SET v_fecha=DATE_ADD(v_fecha,INTERVAL (MOD(i,3)*3) HOUR);
            INSERT INTO reservas(id_cliente,numero_mesa,fecha_reserva)
            VALUES (v_cliente,101+MOD(i-1,24),v_fecha);
            INSERT INTO little_lemon_seed_refs VALUES
                ('reserva',i,LAST_INSERT_ID());
        END IF;
        SET i=i+1;
    END WHILE;

    -- 240 pedidos, cada uno con 1..4 lineas reales.
    -- Cantidad y TotalCost se obtienen de detalle_pedido.
    SET i=1;
    WHILE i<=240 DO
        IF NOT EXISTS (SELECT 1 FROM little_lemon_seed_refs
                       WHERE entity_type='pedido' AND seed_number=i) THEN
            SELECT entity_id INTO v_cliente FROM little_lemon_seed_refs
            WHERE entity_type='cliente' AND seed_number=1+MOD(i-1,120);
            SELECT entity_id INTO v_personal FROM little_lemon_seed_refs
            WHERE entity_type='personal' AND seed_number=1+MOD(i-1,24);
            SET v_reserva=NULL;
            IF i<=90 THEN
                SELECT entity_id INTO v_reserva FROM little_lemon_seed_refs
                WHERE entity_type='reserva' AND seed_number=i;
                SELECT fecha_reserva INTO v_fecha FROM reservas
                WHERE id_reserva=v_reserva;
            ELSE
                SET v_fecha=DATE_ADD('2026-10-01 12:00:00',
                                     INTERVAL MOD(i-1,40) DAY);
                SET v_fecha=DATE_ADD(v_fecha,INTERVAL MOD(i,9) HOUR);
            END IF;

            SET v_num_item=1+MOD(i*7+11,48);
            SELECT entity_id INTO v_menu FROM little_lemon_seed_refs
            WHERE entity_type='menu' AND seed_number=v_num_item;

            INSERT INTO pedidos(id_cliente,id_reserva,id_personal,
                                fecha_pedido,Quantity,TotalCost,MenuID)
            VALUES(v_cliente,v_reserva,v_personal,v_fecha,0,0.00,v_menu);
            SET v_pedido=LAST_INSERT_ID();
            INSERT INTO little_lemon_seed_refs VALUES ('pedido',i,v_pedido);

            SET v_lineas=1+MOD(i,4);
            SET v_total_cantidad=0;
            SET v_total=0.00;
            SET j=1;
            WHILE j<=v_lineas DO
                SET v_num_item=1+MOD(i*7+j*11,48);
                SELECT entity_id INTO v_item FROM little_lemon_seed_refs
                WHERE entity_type='item' AND seed_number=v_num_item;
                SELECT precio INTO v_precio FROM menu_items WHERE id_item=v_item;
                SET v_cantidad=1+MOD(i+j,3);
                INSERT INTO detalle_pedido(id_pedido,id_item,cantidad,precio_unitario)
                VALUES(v_pedido,v_item,v_cantidad,v_precio);
                SET v_total_cantidad=v_total_cantidad+v_cantidad;
                SET v_total=v_total+(v_cantidad*v_precio);
                SET j=j+1;
            END WHILE;
            UPDATE pedidos SET Quantity=v_total_cantidad,TotalCost=v_total
            WHERE id_pedido=v_pedido;

            -- Historial temporal: la mayoria progresa hasta 'Entregado'.
            -- Algunos se cancelan en el paso 3.
            SET v_num_estados=1+MOD(i,5);
            IF MOD(i,17)=0 THEN SET v_num_estados=3; END IF;
            SET j=1;
            WHILE j<=v_num_estados DO
                SET v_nombre=CASE
                    WHEN MOD(i,17)=0 AND j=3 THEN 'Cancelado'
                    WHEN j=1 THEN 'Pendiente'
                    WHEN j=2 THEN 'En preparacion'
                    WHEN j=3 THEN 'Listo'
                    WHEN j=4 THEN 'En camino'
                    ELSE 'Entregado' END;
                SELECT id_estado INTO v_estado FROM estados_entrega
                WHERE nombre_estado=v_nombre;
                INSERT INTO historial_entregas(id_pedido,id_estado,fecha_estado)
                VALUES(v_pedido,v_estado,DATE_ADD(v_fecha,INTERVAL ((j-1)*25) MINUTE));
                SET j=j+1;
            END WHILE;
        END IF;
        SET i=i+1;
    END WHILE;

    COMMIT;
    DROP TEMPORARY TABLE IF EXISTS ll_seed_menu_def;
END$$
DELIMITER ;

CALL poblar_little_lemon();
DROP PROCEDURE IF EXISTS poblar_little_lemon;

-- ================================================================
-- VALIDACION Y EJEMPLOS DE CONSULTA
-- ================================================================
SELECT entity_type, COUNT(*) AS registros_demo
FROM little_lemon_seed_refs
GROUP BY entity_type
ORDER BY entity_type;

SELECT 'detalle_pedido' AS tabla, COUNT(*) AS cantidad
FROM detalle_pedido
UNION ALL
SELECT 'historial_entregas', COUNT(*) FROM historial_entregas;

-- Los campos de Orders coinciden con los detalles de los pedidos demo.
SELECT COUNT(*) AS pedidos_con_totales_inconsistentes
FROM pedidos p
JOIN little_lemon_seed_refs r
  ON r.entity_type='pedido' AND r.entity_id=p.id_pedido
JOIN (
    SELECT id_pedido, SUM(cantidad) AS qty,
           SUM(cantidad*precio_unitario) AS total
    FROM detalle_pedido GROUP BY id_pedido
) d ON d.id_pedido=p.id_pedido
WHERE p.Quantity<>d.qty OR p.TotalCost<>d.total;

-- Vista, JOIN y subconsulta para las actividades de Coursera.
CREATE OR REPLACE VIEW LittleLemonOrdersView AS
SELECT OrderID, Quantity, TotalCost FROM Orders WHERE Quantity>2;

SELECT c.CustomerName, o.OrderID, o.Quantity, o.TotalCost,
       m.MenuName, mi.ItemName, mi.Category
FROM Customers c
JOIN Orders o ON o.CustomerID=c.CustomerID
JOIN Menus m ON m.MenuID=o.MenuID
JOIN MenuItems mi ON mi.MenuItemsID=m.MenuItemsID
ORDER BY o.OrderID DESC LIMIT 20;

SELECT CustomerID, CustomerName
FROM Customers
WHERE CustomerID IN (
    SELECT CustomerID FROM Orders WHERE TotalCost>100
)
LIMIT 20;
