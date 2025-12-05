-- 1. MARCAS (Solo familia ADO)
INSERT INTO marca (marca_id, nombre, tipo_servicio) VALUES
(1, 'ADO Mobility', 'Primera'),
(2, 'ADO Aeropuerto', 'Primera'),
(3, 'ADO Aeropuerto Sprinter', 'Conexión'),
(4, 'ADO Conecta', 'Conexión'),
(5, 'ADO GL', 'Ejecutivo'),
(6, 'ADO Platino', 'Lujo');

-- 2. AMENIDADES (Se conservan todas porque GL y Platino las usan)
INSERT INTO amenidad (amenidad_id, nombre) VALUES
(1, 'Aire Acondicionado'),
(2, 'Portaequipaje'),
(3, 'Pantallas de Alta Definición'),
(4, 'Sanitario'),
(5, 'Sanitarios Independientes'),
(6, 'WiFi'),
(7, 'Conexiones Eléctricas y USB'),
(8, 'Asientos con Memoria'),
(9, 'Canales de Audio Individual'),
(10, 'Bebida de Cortesía'),
(11, 'Asiento Tipo Reposet'),
(12, 'Mesa Plegable'),
(13, 'Sistema de Entretenimiento Individual'),
(14, 'Sala de Espera Exclusiva'),
(15, 'Bluetooth'),
(16, 'Cafetería a Bordo');

INSERT INTO marca_amenidad (marca_id, amenidad_id) VALUES

(1, 1), (1, 2), (1, 3), (1, 4), (1, 6),

(2, 1), (2, 2), (2, 3), (2, 4),

(3, 1), (3, 2), (3, 7),

(4, 1), (4, 2),

(5, 1), (5, 2), (5, 3), (5, 5), (5, 6), (5, 7), (5, 8), (5, 9), (5, 10), (5, 16),

(6, 1), (6, 2), (6, 5), (6, 6), (6, 7), (6, 9), (6, 10), (6, 11), (6, 12), (6, 13), (6, 14), (6, 15), (6, 16);