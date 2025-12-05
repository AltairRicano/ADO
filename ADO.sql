-- Active: 1764738039348@@100.97.178.90@5431@ado_produccion

-- =============================================
-- 1. LIMPIEZA TOTAL (DROP CASCADA)
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
DROP TABLE IF EXISTS pasajeros CASCADE;
DROP TABLE IF EXISTS pasajero CASCADE;
DROP TABLE IF EXISTS cliente_registrado CASCADE;
DROP TABLE IF EXISTS cuenta CASCADE;
DROP TABLE IF EXISTS cliente CASCADE;
DROP TABLE IF EXISTS asiento CASCADE;
DROP TABLE IF EXISTS marca_amenidad CASCADE;
DROP TABLE IF EXISTS amenidad CASCADE;
DROP TABLE IF EXISTS vehiculo CASCADE;
DROP TABLE IF EXISTS marca CASCADE;
DROP TABLE IF EXISTS chofer CASCADE;
DROP TABLE IF EXISTS empleado CASCADE;
DROP TABLE IF EXISTS corrida CASCADE;
DROP TABLE IF EXISTS escala CASCADE;
DROP TABLE IF EXISTS ruta CASCADE;
DROP TABLE IF EXISTS terminal CASCADE;
DROP TABLE IF EXISTS poblacion CASCADE;
DROP TABLE IF EXISTS estado CASCADE;

-- =============================================
-- 2. UBICACIONES Y LOGÍSTICA
-- =============================================

CREATE TABLE estado (
    estado_id SERIAL PRIMARY KEY,
    nombre VARCHAR(32) NOT NULL,
    codigo_estado VARCHAR(4) NOT NULL
);

CREATE TABLE poblacion (
    poblacion_id SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    estado_id INT NOT NULL,

    CONSTRAINT fk_estado
        FOREIGN KEY (estado_id) REFERENCES estado(estado_id)
);

CREATE TABLE terminal (
    terminal_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    direccion TEXT NOT NULL,
    codigo_postal VARCHAR(10) NOT NULL,
    horario_apertura TIME,
    horario_cierre TIME,
    poblacion_id INT NOT NULL,

    CONSTRAINT fk_poblacion_id
        FOREIGN KEY (poblacion_id) REFERENCES poblacion(poblacion_id)
);

CREATE TABLE ruta (
    ruta_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),          
    distancia NUMERIC(10,2) NOT NULL,
    tipo_corrida VARCHAR(50)       
);

CREATE TABLE escala (
    ruta_padre_id INT NOT NULL,  
    ruta_hijo_id INT NOT NULL,   
    orden INT NOT NULL,          
    
    CONSTRAINT fk_ruta_padre 
        FOREIGN KEY (ruta_padre_id) REFERENCES ruta(ruta_id),
    CONSTRAINT fk_ruta_hijo 
        FOREIGN KEY (ruta_hijo_id) REFERENCES ruta(ruta_id),
    CONSTRAINT pk_escala 
        PRIMARY KEY (ruta_padre_id, ruta_hijo_id)
);

CREATE TABLE corrida (
    corrida_id SERIAL PRIMARY KEY,
    fecha_hora_salida TIMESTAMP,
    fecha_hora_llegada TIMESTAMP,
    costo_base NUMERIC(6,2),
    ruta_id INT NOT NULL, 
    
    CONSTRAINT fk_ruta_corrida
        FOREIGN KEY (ruta_id) REFERENCES ruta(ruta_id)
);

-- =============================================
-- 3. PERSONAL Y FLOTA
-- =============================================

CREATE TABLE empleado (
    empleado_id SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    apellido_paterno VARCHAR(40) NOT NULL,
    apellido_materno VARCHAR(40) NOT NULL,
    tipo_empleado VARCHAR(50) NOT NULL,
    nss CHAR(11) NOT NULL,
    rfc VARCHAR(13) NOT NULL,
    curp CHAR(18) NOT NULL
);

CREATE TABLE chofer (
    chofer_id INT PRIMARY KEY,
    estado_actual VARCHAR(32) NOT NULL,
    horas_conduccion NUMERIC DEFAULT 0,
    numero_licencia VARCHAR(50) NOT NULL,
    vencimiento_licencia DATE NOT NULL,

    CONSTRAINT fk_chofer_empleado
        FOREIGN KEY (chofer_id) REFERENCES empleado(empleado_id)
);

CREATE TABLE marca (
    marca_id SERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    tipo_servicio VARCHAR(30) NOT NULL
);

CREATE TABLE vehiculo (
    vehiculo_id SERIAL PRIMARY KEY,
    numero_asientos INT NOT NULL,
    numero_flota VARCHAR(8) NOT NULL,
    estado_vehiculo VARCHAR(10) NOT NULL,
    matricula VARCHAR(10) NOT NULL,
    modelo VARCHAR(20) NOT NULL,
    marca_id INT NOT NULL,

    CONSTRAINT fk_marca_id
        FOREIGN KEY (marca_id) REFERENCES marca(marca_id)
);

CREATE TABLE amenidad (
    amenidad_id SERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL
);

CREATE TABLE marca_amenidad (
    marca_id INT NOT NULL,
    amenidad_id INT NOT NULL,

    CONSTRAINT pk_marca_amenidad
        PRIMARY KEY (marca_id, amenidad_id),
    CONSTRAINT fk_marca_id
        FOREIGN KEY (marca_id) REFERENCES marca(marca_id),
    CONSTRAINT fk_amenidad_id
        FOREIGN KEY (amenidad_id) REFERENCES amenidad(amenidad_id)
);

-- =============================================
-- 4. INVENTARIO
-- =============================================

CREATE TABLE asiento (
    asiento_id SERIAL PRIMARY KEY,
    numero_asiento VARCHAR(4) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Disponible',
    descripcion VARCHAR(50) NOT NULL,
    corrida_id INT NOT NULL,

    CONSTRAINT fk_corrida_id
        FOREIGN KEY (corrida_id) REFERENCES corrida(corrida_id)
);

-- =============================================
-- 5. CLIENTES
-- =============================================

CREATE TABLE cliente (
    cliente_id SERIAL PRIMARY KEY,
    correo VARCHAR(100) UNIQUE, 
    numero_celular VARCHAR(15),

    CONSTRAINT chk_contacto_obligatorio 
    CHECK (correo IS NOT NULL OR numero_celular IS NOT NULL)
);

CREATE TABLE cuenta (
    cuenta_id SERIAL PRIMARY KEY,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE,
    codigo_postal VARCHAR(5), 
    contrasena TEXT NOT NULL,
    genero VARCHAR(10) DEFAULT 'Omitir' NOT NULL,
    cliente_id INT NOT NULL UNIQUE,

    CONSTRAINT fk_cliente_id
        FOREIGN KEY (cliente_id) REFERENCES cliente(cliente_id),
    CONSTRAINT chk_contrasena_segura
        CHECK (LENGTH(contrasena) >= 8),
    CONSTRAINT chk_genero_valido
        CHECK (genero IN ('Femenino', 'Masculino', 'Omitir'))
);

CREATE TABLE pasajero (
    pasajero_id SERIAL PRIMARY KEY,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    cuenta_id INT NOT NULL,
    
    CONSTRAINT fk_cuenta_id
        FOREIGN KEY (cuenta_id) REFERENCES cuenta(cuenta_id)
);

CREATE TABLE favorito (
    favorito_id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL,
    fecha_hora TIMESTAMP NOT NULL DEFAULT NOW(),
    ruta_id INT NOT NULL,
    cuenta_id INT NOT NULL,

    CONSTRAINT fk_cuenta_id
        FOREIGN KEY (cuenta_id) REFERENCES cuenta(cuenta_id),
    CONSTRAINT fk_ruta_id
        FOREIGN KEY (ruta_id) REFERENCES ruta(ruta_id)
);

-- CORRECCIÓN: Ahora apunta a CLIENTE (para incluir invitados)
CREATE TABLE saldo_max (
    saldo_max_id SERIAL PRIMARY KEY,
    nip CHAR(4) NOT NULL,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    saldo NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    fecha_vigencia TIMESTAMP,
    cliente_id INT NOT NULL UNIQUE, 

    CONSTRAINT fk_cliente_id
        FOREIGN KEY (cliente_id) REFERENCES cliente(cliente_id)
);

-- =============================================
-- 6. VENTAS Y PAGOS
-- =============================================

CREATE TABLE descuento (
    descuento_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    porcentaje NUMERIC(3, 2) NOT NULL, 
    cantidad_max INT DEFAULT 0 
);

CREATE TABLE carrito (
    carrito_id SERIAL PRIMARY KEY,
    fecha_creacion TIMESTAMP DEFAULT NOW(),
    tiempo_expiracion TIMESTAMP DEFAULT (NOW() + INTERVAL '30 minutes'),
    total NUMERIC(10,2) DEFAULT 0.00,
    cuenta_id INT NOT NULL,
    
    CONSTRAINT fk_cuenta_id
        FOREIGN KEY (cuenta_id) REFERENCES cuenta(cuenta_id)
        ON DELETE CASCADE 
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
    
    CONSTRAINT fk_carrito_id
        FOREIGN KEY (carrito_id) REFERENCES carrito(carrito_id) ON DELETE CASCADE,
    CONSTRAINT fk_descuento_id
        FOREIGN KEY (descuento_id) REFERENCES descuento(descuento_id)
);

-- VISTA PARA EL CARRITO
CREATE OR REPLACE VIEW carrito_activo AS
SELECT *
FROM carrito
WHERE tiempo_expiracion > NOW();

CREATE TABLE operacion (
    numero_operacion SERIAL PRIMARY KEY,
    total NUMERIC (10,2) NOT NULL,
    fecha_hora TIMESTAMP NOT NULL DEFAULT NOW(),
    cliente_id INT NOT NULL,
    id_empleado_venta INT,
    
    CONSTRAINT fk_cliente_id 
        FOREIGN KEY (cliente_id) REFERENCES cliente(cliente_id)
);

CREATE TABLE detalle_operacion (   
    detalle_operacion_id SERIAL PRIMARY KEY,
    tipo_movimiento CHAR(1) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    monto NUMERIC (10,2) NOT NULL,
    numero_operacion INT NOT NULL,
    
    CONSTRAINT fk_numero_operacion
        FOREIGN KEY (numero_operacion) REFERENCES operacion(numero_operacion)
);

CREATE TABLE metodo_pago (
    pago_id SERIAL PRIMARY KEY,
    estado VARCHAR(20) NOT NULL,
    detalle_operacion_id INT NOT NULL,

    CONSTRAINT fk_detalle_operacion_id
        FOREIGN KEY (detalle_operacion_id) REFERENCES detalle_operacion(detalle_operacion_id)
);

CREATE TABLE paypal (
    pago_id INT PRIMARY KEY,
    correo_cuenta VARCHAR(100) NOT NULL,

    CONSTRAINT fk_metodo_pago
        FOREIGN KEY (pago_id) REFERENCES metodo_pago(pago_id)
);

CREATE TABLE tarjeta (
    pago_id INT PRIMARY KEY,
    banco VARCHAR (50),
    titular_tarjeta VARCHAR (100),
    red_tarjeta VARCHAR(20),

    CONSTRAINT fk_metodo_pago
        FOREIGN KEY (pago_id) REFERENCES metodo_pago(pago_id)
);

CREATE TABLE efectivo (
    pago_id INT PRIMARY KEY,

    CONSTRAINT fk_metodo_pago
        FOREIGN KEY (pago_id) REFERENCES metodo_pago(pago_id)
);

CREATE TABLE paynet (
    pago_id INT PRIMARY KEY,
    referencia_paynet VARCHAR(45),
    punto_cobro VARCHAR(50),
    fecha_generacion TIMESTAMP,
    fecha_expiracion TIMESTAMP,

    CONSTRAINT fk_efectivo_id
        FOREIGN KEY (pago_id) REFERENCES efectivo(pago_id)
);

-- =============================================
-- 7. FINANZAS FINALES Y FACTURACIÓN
-- =============================================

CREATE TABLE detalle_saldo_max (
    detalle_saldo_id SERIAL PRIMARY KEY,
    fecha_hora TIMESTAMP DEFAULT NOW(),
    descripcion VARCHAR(100),
    monto NUMERIC(10,2),
    tipo_movimiento VARCHAR(20),
    saldo_max_id INT NOT NULL,
    pago_id INT UNIQUE,

    CONSTRAINT fk_pago_id
        FOREIGN KEY (pago_id) REFERENCES metodo_pago(pago_id),
    CONSTRAINT fk_saldo_max_id
        FOREIGN KEY (saldo_max_id) REFERENCES saldo_max(saldo_max_id)
);

CREATE TABLE boleto (
    numero_folio CHAR(12) PRIMARY KEY NOT NULL,
    costo_boleto NUMERIC(10,2) NOT NULL,
    tipo_servicio VARCHAR(20) NOT NULL,
    seguro NUMERIC(10,2), 
    nombre_titular VARCHAR(100) NOT NULL,
    apellido_titular VARCHAR(100) NOT NULL,
    numero_operacion INT NOT NULL,
    asiento_id INT NOT NULL,
    descuento_id INT,

    CONSTRAINT fk_asiento_id
        FOREIGN KEY (asiento_id) REFERENCES asiento(asiento_id),
    CONSTRAINT fk_numero_operacion
        FOREIGN KEY (numero_operacion) REFERENCES operacion(numero_operacion),
    CONSTRAINT fk_descuento_boleto
        FOREIGN KEY (descuento_id) REFERENCES descuento(descuento_id)
);

CREATE TABLE factura (
    folio_factura VARCHAR(36) PRIMARY KEY,
    impuestos NUMERIC(10,2) NOT NULL,
    total NUMERIC(10,2) NOT NULL,
    rfc VARCHAR(13) NOT NULL,
    estatus VARCHAR(30) NOT NULL,
    uso_cfdi VARCHAR(5) NOT NULL,
    regimen_fiscal VARCHAR(5) NOT NULL,
    fecha TIMESTAMP NOT NULL DEFAULT NOW(),
    numero_folio CHAR(12) NOT NULL,

    CONSTRAINT fk_numero_folio
        FOREIGN KEY (numero_folio) REFERENCES boleto(numero_folio)
);