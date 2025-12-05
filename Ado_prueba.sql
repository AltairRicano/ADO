-- ============================================================
-- 0. LIMPIEZA GENERAL EN ORDEN CORRECTO
-- ============================================================

DROP VIEW IF EXISTS carrito_activo;

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

-- ============================================================
-- 1. UBICACIONES Y TERMINALES
-- ============================================================

CREATE TABLE estado (
    estado_id SERIAL PRIMARY KEY,
    nombre VARCHAR(32) NOT NULL,
    codigo_estado VARCHAR(4) NOT NULL
);

CREATE TABLE poblacion (
    poblacion_id SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    estado_id INT NOT NULL REFERENCES estado(estado_id)
);

CREATE TABLE terminal (
    terminal_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    direccion TEXT NOT NULL,
    codigo_postal VARCHAR(10) NOT NULL,
    horario_apertura TIME,
    horario_cierre TIME,
    poblacion_id INT NOT NULL REFERENCES poblacion(poblacion_id)
);

-- ============================================================
-- 2. RUTAS Y LOGÍSTICA
-- ============================================================

CREATE TABLE ruta (
    ruta_id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    distancia NUMERIC(10,2) NOT NULL,
    fecha_hora_salida TIMESTAMP,
    fecha_hora_llegada TIMESTAMP,
    tipo_corrida VARCHAR(50)
);

CREATE TABLE escala (
    ruta_padre_id INT NOT NULL,
    ruta_hijo_id INT NOT NULL,
    orden INT NOT NULL,
    PRIMARY KEY (ruta_padre_id, ruta_hijo_id),
    FOREIGN KEY (ruta_padre_id) REFERENCES ruta(ruta_id),
    FOREIGN KEY (ruta_hijo_id) REFERENCES ruta(ruta_id)
);

CREATE TABLE corrida (
    corrida_id SERIAL PRIMARY KEY,
    fecha_hora_salida TIMESTAMP,
    fecha_hora_llegada TIMESTAMP,
    costo_base NUMERIC(6,2)
);

-- ============================================================
-- 3. PERSONAL
-- ============================================================

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
    chofer_id SERIAL PRIMARY KEY,
    estado_actual VARCHAR(32) NOT NULL,
    horas_conduccion NUMERIC DEFAULT 0,
    numero_licencia VARCHAR(50) NOT NULL,
    vencimiento_licencia DATE NOT NULL,
    empleado_id INT NOT NULL REFERENCES empleado(empleado_id)
);

-- ============================================================
-- 4. FLOTA
-- ============================================================

CREATE TABLE marca (
    marca_id SERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    tipo_servicio VARCHAR(30) NOT NULL
);

CREATE TABLE vehiculo (
    vehiculo_id SERIAL PRIMARY KEY,
    numero_asientos VARCHAR(2) NOT NULL,
    numero_flota VARCHAR(8) NOT NULL,
    estado_vehiculo VARCHAR(10) NOT NULL,
    matricula VARCHAR(10) NOT NULL,
    modelo VARCHAR(20) NOT NULL,
    marca_id INT NOT NULL REFERENCES marca(marca_id)
);

CREATE TABLE amenidad (
    amenidad_id SERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL
);

CREATE TABLE marca_amenidad (
    marca_id INT NOT NULL,
    amenidad_id INT NOT NULL,
    PRIMARY KEY (marca_id, amenidad_id),
    FOREIGN KEY (marca_id) REFERENCES marca(marca_id),
    FOREIGN KEY (amenidad_id) REFERENCES amenidad(amenidad_id)
);

-- ============================================================
-- 5. ASIENTOS
-- ============================================================

CREATE TABLE asiento (
    asiento_id SERIAL PRIMARY KEY,
    numero_asiento VARCHAR(2) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    descripcion VARCHAR(10) NOT NULL,
    corrida_id INT NOT NULL REFERENCES corrida(corrida_id)
);

-- ============================================================
-- 6. CLIENTES, CUENTAS Y VENTAS
-- ============================================================

CREATE TABLE cliente (
    cliente_id SERIAL PRIMARY KEY,
    correo VARCHAR(100) UNIQUE,
    numero_celular VARCHAR(15),
    CHECK (correo IS NOT NULL OR numero_celular IS NOT NULL)
);

CREATE TABLE cuenta (
    cuenta_id SERIAL PRIMARY KEY,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE,
    codigo_postal VARCHAR(5),
    contrasena TEXT NOT NULL CHECK (LENGTH(contrasena) >= 8),
    genero VARCHAR(10) NOT NULL DEFAULT 'Omitir'
        CHECK (genero IN ('Femenino','Masculino','Omitir')),
    cliente_id INT NOT NULL UNIQUE REFERENCES cliente(cliente_id)
);

CREATE TABLE pasajero (
    pasajero_id SERIAL PRIMARY KEY,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    cuenta_id INT NOT NULL REFERENCES cuenta(cuenta_id)
);

CREATE TABLE favorito (
    favorito_id SERIAL PRIMARY KEY,
    nombre TEXT NOT NULL,
    fecha_hora TIMESTAMP NOT NULL,
    ruta_id INT NOT NULL REFERENCES ruta(ruta_id),
    cuenta_id INT NOT NULL REFERENCES cuenta(cuenta_id)
);

CREATE TABLE descuento (
    descuento_id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    porcentaje NUMERIC(3,2) NOT NULL,
    cantidad_max INT DEFAULT 0
);

CREATE TABLE carrito (
    carrito_id SERIAL PRIMARY KEY,
    fecha_creacion TIMESTAMP DEFAULT NOW(),
    tiempo_expiracion TIMESTAMP DEFAULT (NOW() + INTERVAL '30 minutes'),
    total NUMERIC(10,2) DEFAULT 0.00,
    cuenta_id INT NOT NULL REFERENCES cuenta(cuenta_id) ON DELETE CASCADE
);

CREATE TABLE detalle_carrito (
    detalle_carrito_id SERIAL PRIMARY KEY,
    precio_venta NUMERIC(10,2),
    fecha_hora TIMESTAMP DEFAULT NOW(),
    seguro BOOLEAN DEFAULT FALSE,
    nombre_titular VARCHAR(100),
    apellido_titular VARCHAR(100),
    carrito_id INT NOT NULL REFERENCES carrito(carrito_id) ON DELETE CASCADE,
    descuento_id INT NOT NULL REFERENCES descuento(descuento_id)
);

CREATE VIEW carrito_activo AS
SELECT *
FROM carrito
WHERE tiempo_expiracion > NOW();

-- ============================================================
-- 7. OPERACIONES Y PAGOS CORREGIDOS COMPLETOS
-- ============================================================

CREATE TABLE operacion (
    numero_operacion SERIAL PRIMARY KEY,
    total NUMERIC(7,2) NOT NULL,
    fecha_hora TIMESTAMP NOT NULL DEFAULT NOW(),
    cliente_id INT NOT NULL REFERENCES cliente(cliente_id)
);

CREATE TABLE detalle_operacion (
    detalle_operacion_id SERIAL PRIMARY KEY,
    tipo_movimiento CHAR(1) NOT NULL,
    descripcion VARCHAR(100) NOT NULL,
    monto NUMERIC(6,2) NOT NULL,
    numero_operacion INT NOT NULL REFERENCES operacion(numero_operacion)
);

CREATE TABLE metodo_pago (
    pago_id SERIAL PRIMARY KEY,
    estado CHAR(1) NOT NULL,
    detalle_operacion_id INT NOT NULL REFERENCES detalle_operacion(detalle_operacion_id)
);

CREATE TABLE paypal (
    paypal_id INT PRIMARY KEY REFERENCES metodo_pago(pago_id),
    correo_cuenta VARCHAR(40) NOT NULL
);

CREATE TABLE tarjeta (
    tarjeta_id INT PRIMARY KEY REFERENCES metodo_pago(pago_id),
    banco VARCHAR(15),
    titular_tarjeta VARCHAR(100),
    red_tarjeta VARCHAR(10)
);

CREATE TABLE efectivo (
    efectivo_id INT PRIMARY KEY REFERENCES metodo_pago(pago_id)
);

CREATE TABLE paynet (
    paynet_id INT PRIMARY KEY REFERENCES metodo_pago(pago_id),
    referencia_paynet VARCHAR(45),
    punto_cobro VARCHAR(35),
    fecha_generacion TIMESTAMP,
    fecha_expiracion TIMESTAMP,
    efectivo_id INT NOT NULL REFERENCES efectivo(efectivo_id)
);

-- ============================================================
-- 8. SALDO MÁXIMO (CORREGIDO)
-- ============================================================

CREATE TABLE saldo_max (
    saldo_max_id SERIAL PRIMARY KEY,
    nip CHAR(4) NOT NULL,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT NOW(),
    saldo NUMERIC(7,2) NOT NULL,
    fecha_vigencia TIMESTAMP NOT NULL,
    cuenta_id INT NOT NULL UNIQUE REFERENCES cuenta(cuenta_id)
);

CREATE TABLE detalle_saldo_max (
    detalle_saldo_id SERIAL PRIMARY KEY,
    fecha_hora TIMESTAMP,
    descripcion CHAR(1),
    monto NUMERIC(10,2),
    fecha_movimiento TIMESTAMP,
    saldo_max_id INT NOT NULL REFERENCES saldo_max(saldo_max_id),
    pago_id INT NOT NULL UNIQUE REFERENCES metodo_pago(pago_id)
);

-- ============================================================
-- 9. BOLETOS Y FACTURAS
-- ============================================================

CREATE TABLE boleto (
    numero_folio CHAR(12) PRIMARY KEY,
    costo_boleto NUMERIC(6,2) NOT NULL,
    tipo_servicio VARCHAR(10) NOT NULL,
    seguro NUMERIC(2,0) CHECK (seguro IS NULL OR seguro = 17),
    nombre_titular VARCHAR(40) NOT NULL,
    apellido_titular VARCHAR(40) NOT NULL,
    numero_operacion INT NOT NULL REFERENCES operacion(numero_operacion),
    asiento_id INT NOT NULL REFERENCES asiento(asiento_id)
);

CREATE TABLE factura (
    folio_factura CHAR(36) PRIMARY KEY,
    impuestos NUMERIC(6,2) NOT NULL,
    total NUMERIC(7,2) NOT NULL,
    rfc CHAR(13) NOT NULL,
    estatus VARCHAR(30) NOT NULL,
    uso_cfdi CHAR(3) NOT NULL,
    regimen_fiscal CHAR(3) NOT NULL,
    fecha TIMESTAMP NOT NULL DEFAULT NOW(),
    numero_folio CHAR(12) NOT NULL REFERENCES boleto(numero_folio)
);
