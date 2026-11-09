CREATE DATABASE IF NOT EXISTS LittleLemonDM;
USE LittleLemonDM;

CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    telefono VARCHAR(20),
    email VARCHAR(100) UNIQUE
);

CREATE TABLE mesas (
    numero_mesa INT PRIMARY KEY,
    capacidad INT NOT NULL,
    CHECK (capacidad > 0)
);

CREATE TABLE reservas (
    id_reserva INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    numero_mesa INT NOT NULL,
    fecha_reserva DATETIME NOT NULL,

    FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente),

    FOREIGN KEY (numero_mesa)
        REFERENCES mesas(numero_mesa)
);

CREATE TABLE roles (
    id_rol INT AUTO_INCREMENT PRIMARY KEY,
    nombre_rol VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE personal (
    id_personal INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    id_rol INT NOT NULL,
    salario DECIMAL(12,2) NOT NULL,

    CHECK (salario >= 0),

    FOREIGN KEY (id_rol)
        REFERENCES roles(id_rol)
);

CREATE TABLE cocinas (
    id_cocina INT AUTO_INCREMENT PRIMARY KEY,
    nombre_cocina VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE categorias_menu (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre_categoria VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE menu_items (
    id_item INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255),
    precio DECIMAL(10,2) NOT NULL,
    id_categoria INT NOT NULL,
    id_cocina INT,

    CHECK (precio >= 0),

    FOREIGN KEY (id_categoria)
        REFERENCES categorias_menu(id_categoria),

    FOREIGN KEY (id_cocina)
        REFERENCES cocinas(id_cocina)
);

CREATE TABLE pedidos (
    id_pedido INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_reserva INT,
    id_personal INT,
    fecha_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente),

    FOREIGN KEY (id_reserva)
        REFERENCES reservas(id_reserva),

    FOREIGN KEY (id_personal)
        REFERENCES personal(id_personal)
);

CREATE TABLE detalle_pedido (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_item INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,

    CHECK (cantidad > 0),
    CHECK (precio_unitario >= 0),

    FOREIGN KEY (id_pedido)
        REFERENCES pedidos(id_pedido),

    FOREIGN KEY (id_item)
        REFERENCES menu_items(id_item)
);

CREATE TABLE estados_entrega (
    id_estado INT AUTO_INCREMENT PRIMARY KEY,
    nombre_estado VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE historial_entregas (
    id_historial INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido INT NOT NULL,
    id_estado INT NOT NULL,
    fecha_estado DATETIME NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_pedido)
        REFERENCES pedidos(id_pedido),

    FOREIGN KEY (id_estado)
        REFERENCES estados_entrega(id_estado)
);

CREATE VIEW vista_totales_pedidos AS
SELECT
    p.id_pedido,
    p.fecha_pedido,
    COALESCE(SUM(d.cantidad), 0) AS cantidad_total,
    COALESCE(
        SUM(d.cantidad * d.precio_unitario),
        0
    ) AS costo_total
FROM pedidos p
LEFT JOIN detalle_pedido d
    ON p.id_pedido = d.id_pedido
GROUP BY p.id_pedido, p.fecha_pedido;

INSERT INTO roles (nombre_rol)
VALUES
('Gerente'),
('Camarero'),
('Cocinero'),
('Repartidor');

INSERT INTO categorias_menu (nombre_categoria)
VALUES
('Entrante'),
('Plato principal'),
('Bebida'),
('Postre');

INSERT INTO cocinas (nombre_cocina)
VALUES
('Argentina'),
('Italiana'),
('Mexicana'),
('Japonesa');

INSERT INTO estados_entrega (nombre_estado)
VALUES
('Pendiente'),
('En preparacion'),
('Listo'),
('En camino'),
('Entregado'),
('Cancelado');
