-- =============================================
-- 1. LIMPIEZA (DROP EN CASCADA)
-- =============================================
DROP TABLE IF EXISTS factura CASCADE;
DROP TABLE IF EXISTS boleto CASCADE;
DROP TABLE IF EXISTS detalle_saldo_max CASCADE;
DROP TABLE IF EXISTS saldo_max CASCADE;
DROP TABLE IF EXISTS paynet CASCADE;
DROP TABLE IF EXISTS efectivo CASCADE;
DROP TABLE IF EXISTS tarjeta CASCADE;
DROP TABLE IF EXISTS paypal CASCADE;
DROP TABLE IF EXISTS metodo_pago CASCADE;
DROP TABLE IF EXISTS detalle_operacion CASCADE;
DROP TABLE IF EXISTS operacion CASCADE;
DROP TABLE IF EXISTS detalle_carrito CASCADE;

DROP TABLE IF EXISTS carrito CASCADE;
DROP TABLE IF EXISTS descuento CASCADE;
DROP TABLE IF EXISTS favorito CASCADE;
DROP TABLE IF EXISTS pasajero CASCADE;
DROP TABLE IF EXISTS cuenta CASCADE;
DROP TABLE IF EXISTS cliente CASCADE;

DROP TABLE IF EXISTS asiento CASCADE;
DROP TABLE IF EXISTS corrida CASCADE;
DROP TABLE IF EXISTS escala CASCADE;
DROP TABLE IF EXISTS ruta CASCADE;
DROP TABLE IF EXISTS parada_cortesia CASCADE;
DROP TABLE IF EXISTS marca_amenidad CASCADE;
DROP TABLE IF EXISTS amenidad CASCADE;
DROP TABLE IF EXISTS vehiculo CASCADE;
DROP TABLE IF EXISTS marca CASCADE;
DROP TABLE IF EXISTS chofer CASCADE;
DROP TABLE IF EXISTS empleado CASCADE;
DROP TABLE IF EXISTS terminal CASCADE;
DROP TABLE IF EXISTS poblacion CASCADE;
DROP TABLE IF EXISTS estado CASCADE;

-- =============================================
-- 2. CATÁLOGOS BASE (Sin dependencias)
-- =============================================

CREATE TABLE estado (
    estado_id SERIAL PRIMARY KEY,
    nombre VARCHAR(32) NOT NULL,
    codigo_estado VARCHAR(4) NOT NULL
);

CREATE TABLE marca (
    marca_id SERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    tipo_servicio VARCHAR(30) NOT NULL
);

CREATE TABLE amenidad (
    amenidad_id SERIAL PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL
);

CREATE TABLE empleado (
    empleado_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido_paterno VARCHAR(100) NOT NULL,
    apellido_materno VARCHAR(100) NOT NULL,
    tipo_empleado VARCHAR(50) NOT NULL,
    nss VARCHAR(11) NOT NULL,
    rfc VARCHAR(13) NOT NULL,
    curp VARCHAR(18) NOT NULL
);

CREATE TABLE cliente (
    cliente_id SERIAL PRIMARY KEY,
    correo VARCHAR(100) UNIQUE, 
    numero_celular VARCHAR(15),
    CONSTRAINT chk_contacto_obligatorio 
        CHECK (correo IS NOT NULL OR numero_celular IS NOT NULL)
);

CREATE TABLE descuento (
    descuento_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    porcentaje NUMERIC(3, 2) NOT NULL, 
    cantidad_max INT DEFAULT 0 
);

-- =============================================
-- 3. NIVEL 1 (Dependen de los anteriores)
-- =============================================

CREATE TABLE poblacion (
    poblacion_id SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    estado_id INT NOT NULL,
    CONSTRAINT fk_estado FOREIGN KEY (estado_id) REFERENCES estado(estado_id)
);

CREATE TABLE marca_amenidad (
    marca_id INT NOT NULL,
    amenidad_id INT NOT NULL,
    CONSTRAINT pk_marca_amenidad PRIMARY KEY (marca_id, amenidad_id),
    CONSTRAINT fk_marca_id FOREIGN KEY (marca_id) REFERENCES marca(marca_id),
    CONSTRAINT fk_amenidad_id FOREIGN KEY (amenidad_id) REFERENCES amenidad(amenidad_id)
);

-- AQUÍ ESTÁ VEHÍCULO (Antes de Corrida)
CREATE TABLE vehiculo (
    vehiculo_id SERIAL PRIMARY KEY,
    matricula VARCHAR(10) NOT NULL,
    marca_id INT NOT NULL,
    modelo VARCHAR(50) NOT NULL,
    numero_asientos INT NOT NULL,
    estado_vehiculo VARCHAR(10) NOT NULL,
    CONSTRAINT fk_marca_id FOREIGN KEY (marca_id) REFERENCES marca(marca_id)
);

-- AQUÍ ESTÁ CHOFER (Antes de Corrida)
CREATE TABLE chofer (
    chofer_id INT PRIMARY KEY,
    vencimiento_licencia DATE NOT NULL,
    estado_actual VARCHAR(100) NOT NULL,
    horas_conduccion NUMERIC DEFAULT 0,
    numero_licencia VARCHAR(50) NOT NULL,
    CONSTRAINT fk_chofer_empleado FOREIGN KEY (chofer_id) REFERENCES empleado(empleado_id)
);

CREATE TABLE cuenta (
    cuenta_id INT PRIMARY KEY,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE,
    codigo_postal VARCHAR(10), 
    contrasena TEXT NOT NULL,
    genero VARCHAR(10) DEFAULT 'Omitir' NOT NULL,
    CONSTRAINT fk_cuenta_cliente FOREIGN KEY (cuenta_id) REFERENCES cliente(cliente_id),
    CONSTRAINT chk_contrasena_segura CHECK (LENGTH(contrasena) >= 8),
    CONSTRAINT chk_genero_valido CHECK (genero IN ('Femenino', 'Masculino', 'Omitir'))
);

CREATE TABLE saldo_max (
    saldo_max_id SERIAL PRIMARY KEY,
    nip CHAR(4) NOT NULL,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    saldo NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    fecha_vigencia TIMESTAMP,
    cliente_id INT NOT NULL UNIQUE, 
    CONSTRAINT fk_cliente_id FOREIGN KEY (cliente_id) REFERENCES cliente(cliente_id)
);

-- =============================================
-- 4. NIVEL 2 (Logística y Ventas)
-- =============================================

CREATE TABLE terminal (
    terminal_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    direccion TEXT NOT NULL,
    codigo_postal VARCHAR(10) NOT NULL,
    horario_apertura TIME,
    horario_cierre TIME,
    poblacion_id INT NOT NULL,
    CONSTRAINT fk_poblacion_id FOREIGN KEY (poblacion_id) REFERENCES poblacion(poblacion_id)
);

CREATE TABLE pasajero (
    pasajero_id SERIAL PRIMARY KEY,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    cuenta_id INT NOT NULL,
    CONSTRAINT fk_cuenta_id FOREIGN KEY (cuenta_id) REFERENCES cuenta(cuenta_id)
);

CREATE TABLE carrito (
    carrito_id SERIAL PRIMARY KEY,
    fecha_creacion TIMESTAMP DEFAULT NOW(),
    tiempo_expiracion TIMESTAMP DEFAULT (NOW() + INTERVAL '30 minutes'),
    total NUMERIC(10,2) DEFAULT 0.00,
    cuenta_id INT NOT NULL,
    CONSTRAINT fk_cuenta_id FOREIGN KEY (cuenta_id) REFERENCES cuenta(cuenta_id) ON DELETE CASCADE 
);

CREATE TABLE operacion (
    numero_operacion SERIAL PRIMARY KEY,
    total NUMERIC (10,2) NOT NULL,
    fecha_hora TIMESTAMP NOT NULL DEFAULT NOW(),
    cliente_id INT NOT NULL,
    id_empleado_venta INT,
    CONSTRAINT fk_cliente_id FOREIGN KEY (cliente_id) REFERENCES cliente(cliente_id)
);

-- =============================================
-- 5. NIVEL 3 (Rutas y Detalles)
-- =============================================

CREATE TABLE ruta (
    ruta_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),          
    tipo_corrida VARCHAR(50),
    terminal_salida_id INT NOT NULL,
    terminal_llegada_id INT NOT NULL,
    CONSTRAINT fk_ruta_salida FOREIGN KEY (terminal_salida_id) REFERENCES terminal(terminal_id),
    CONSTRAINT fk_ruta_llegada FOREIGN KEY (terminal_llegada_id) REFERENCES terminal(terminal_id)
);

CREATE TABLE parada_cortesia(
    cortesia_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    direccion VARCHAR(100) NOT NULL,
    codigo_postal VARCHAR(10) NOT NULL,
    horario_apertura TIME,
    horario_cierre TIME,
    ruta_id INT NOT NULL,
    CONSTRAINT fk_ruta_id FOREIGN KEY (ruta_id) REFERENCES ruta(ruta_id)
);

CREATE TABLE detalle_carrito (
    detalle_carrito_id SERIAL PRIMARY KEY,
    precio_venta NUMERIC(10,2), 
    fecha_hora TIMESTAMP DEFAULT NOW(),
    seguro BOOLEAN DEFAULT FALSE,
    nombre_titular VARCHAR(100),
    apellido_titular VARCHAR(100),
    carrito_id INT NOT NULL,
    descuento_id INT NOT NULL, 
    CONSTRAINT fk_carrito_id FOREIGN KEY (carrito_id) REFERENCES carrito(carrito_id) ON DELETE CASCADE,
    CONSTRAINT fk_descuento_id FOREIGN KEY (descuento_id) REFERENCES descuento(descuento_id)
);

CREATE OR REPLACE VIEW carrito_activo AS
SELECT * FROM carrito WHERE tiempo_expiracion > NOW();

CREATE TABLE detalle_operacion (   
    detalle_operacion_id SERIAL PRIMARY KEY,
    tipo_movimiento CHAR(1) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    monto NUMERIC (10,2) NOT NULL,
    numero_operacion INT NOT NULL,
    CONSTRAINT fk_numero_operacion FOREIGN KEY (numero_operacion) REFERENCES operacion(numero_operacion)
);

CREATE TABLE favorito (
    favorito_id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL,
    fecha_hora TIMESTAMP NOT NULL DEFAULT NOW(),
    ruta_id INT NOT NULL,
    cuenta_id INT NOT NULL,
    CONSTRAINT fk_cuenta_id FOREIGN KEY (cuenta_id) REFERENCES cuenta(cuenta_id),
    CONSTRAINT fk_ruta_id FOREIGN KEY (ruta_id) REFERENCES ruta(ruta_id)
);

-- =============================================
-- 6. NIVEL 4 (Corrida, Pagos y Escalas)
-- =============================================

CREATE TABLE escala (
    ruta_padre_id INT NOT NULL,  
    ruta_hijo_id INT NOT NULL,   
    orden INT NOT NULL,          
    CONSTRAINT fk_ruta_padre FOREIGN KEY (ruta_padre_id) REFERENCES ruta(ruta_id),
    CONSTRAINT fk_ruta_hijo FOREIGN KEY (ruta_hijo_id) REFERENCES ruta(ruta_id),
    CONSTRAINT pk_escala PRIMARY KEY (ruta_padre_id, ruta_hijo_id)
);

-- AHORA SÍ: Corrida se crea después de Ruta, Chofer y Vehículo
CREATE TABLE corrida (
    corrida_id SERIAL PRIMARY KEY,
    fecha_hora_salida TIMESTAMP,
    fecha_hora_llegada TIMESTAMP,
    costo_base NUMERIC(6,2) DEFAULT 0.00,
    ruta_id INT NOT NULL,
    chofer_id INT NOT NULL,
    vehiculo_id INT NOT NULL,
    CONSTRAINT fk_corrida_ruta FOREIGN KEY (ruta_id) REFERENCES ruta(ruta_id),
    CONSTRAINT fk_corrida_chofer FOREIGN KEY (chofer_id) REFERENCES chofer(chofer_id),
    CONSTRAINT fk_corrida_vehiculo FOREIGN KEY (vehiculo_id) REFERENCES vehiculo(vehiculo_id)
);

CREATE TABLE metodo_pago (
    pago_id SERIAL PRIMARY KEY,
    estado VARCHAR(20) NOT NULL,
    detalle_operacion_id INT NOT NULL,
    CONSTRAINT fk_detalle_operacion_id FOREIGN KEY (detalle_operacion_id) REFERENCES detalle_operacion(detalle_operacion_id)
);

-- =============================================
-- 7. NIVEL 5 (Hijos de Pagos y Asientos)
-- =============================================

CREATE TABLE asiento (
    asiento_id SERIAL PRIMARY KEY,
    numero_asiento VARCHAR(4) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Disponible',
    descripcion VARCHAR(50) NOT NULL,
    corrida_id INT NOT NULL,
    CONSTRAINT fk_corrida_id FOREIGN KEY (corrida_id) REFERENCES corrida(corrida_id)
);

CREATE TABLE paypal (
    pago_id INT PRIMARY KEY,
    correo_cuenta VARCHAR(100) NOT NULL,
    CONSTRAINT fk_pago_id FOREIGN KEY (pago_id) REFERENCES metodo_pago(pago_id)
);

CREATE TABLE tarjeta (
    pago_id INT PRIMARY KEY,
    banco VARCHAR (50),
    titular_tarjeta VARCHAR (100),
    red_tarjeta VARCHAR(20),
    CONSTRAINT fk_pago_id FOREIGN KEY (pago_id) REFERENCES metodo_pago(pago_id)
);

CREATE TABLE efectivo (
    pago_id INT PRIMARY KEY,
    monto_pagado NUMERIC(10,2),
    cambio NUMERIC(10,2),
    CONSTRAINT fk_pago_id FOREIGN KEY (pago_id) REFERENCES metodo_pago(pago_id)
);

CREATE TABLE detalle_saldo_max (
    detalle_saldo_id SERIAL PRIMARY KEY,
    fecha_hora TIMESTAMP DEFAULT NOW(),
    descripcion VARCHAR(100),
    monto NUMERIC(10,2),
    tipo_movimiento VARCHAR(20),
    saldo_max_id INT NOT NULL,
    pago_id INT UNIQUE,
    CONSTRAINT fk_pago_id FOREIGN KEY (pago_id) REFERENCES metodo_pago(pago_id),
    CONSTRAINT fk_saldo_max_id FOREIGN KEY (saldo_max_id) REFERENCES saldo_max(saldo_max_id)
);

CREATE TABLE paynet (
    pago_id INT PRIMARY KEY,
    referencia_paynet VARCHAR(45),
    punto_cobro VARCHAR(50),
    fecha_generacion TIMESTAMP,
    fecha_expiracion TIMESTAMP,
    CONSTRAINT fk_metodo_pago FOREIGN KEY (pago_id) REFERENCES metodo_pago(pago_id)
);

-- =============================================
-- 8. NIVEL 6 (Hijos de Efectivo y Boletos)
-- =============================================

CREATE TABLE boleto (
    numero_folio VARCHAR(20) PRIMARY KEY,
    costo_boleto NUMERIC(10,2) NOT NULL,
    tipo_servicio VARCHAR(20) NOT NULL,
    seguro NUMERIC(10,2), 
    nombre_titular VARCHAR(100) NOT NULL,
    apellido_titular VARCHAR(100) NOT NULL,
    numero_operacion INT NOT NULL,
    asiento_id INT NOT NULL,
    descuento_id INT,
    CONSTRAINT fk_asiento_id FOREIGN KEY (asiento_id) REFERENCES asiento(asiento_id),
    CONSTRAINT fk_numero_operacion FOREIGN KEY (numero_operacion) REFERENCES operacion(numero_operacion),
    CONSTRAINT fk_descuento_boleto FOREIGN KEY (descuento_id) REFERENCES descuento(descuento_id)
);

-- =============================================
-- 9. NIVEL FINAL (Factura)
-- =============================================

CREATE TABLE factura (
    folio_factura VARCHAR(36) PRIMARY KEY,
    impuestos NUMERIC(10,2) NOT NULL,
    total NUMERIC(10,2) NOT NULL,
    rfc VARCHAR(13) NOT NULL,
    calle VARCHAR(100) NOT NULL,
    numero_exterior VARCHAR(20) NOT NULL,
    numero_interior VARCHAR(20),
    colonia VARCHAR(100) NOT NULL,
    municipio_delegacion VARCHAR(100) NOT NULL,
    estado VARCHAR(50) NOT NULL,
    codigo_postal VARCHAR(10) NOT NULL,
    pais VARCHAR(50) NOT NULL DEFAULT 'MEXICO',
    nacionalidad VARCHAR(50) NOT NULL,
    correo_electronico VARCHAR(100) NOT NULL,
    estatus VARCHAR(30) NOT NULL,
    uso_cfdi VARCHAR(5) NOT NULL,
    regimen_fiscal VARCHAR(5) NOT NULL,
    fecha TIMESTAMP NOT NULL DEFAULT NOW(),
    numero_folio VARCHAR(20) NOT NULL,
    CONSTRAINT fk_numero_folio FOREIGN KEY (numero_folio) REFERENCES boleto(numero_folio)
);