-- =======================================================
-- CATÁLOGO MAESTRO DE DESCUENTOS Y TARIFAS
-- =======================================================

INSERT INTO descuento (nombre, descripcion, porcentaje, cantidad_max) VALUES

('Adulto / Entero', 'Precio de lista sin descuento', 0.00, 0), -- 0 = Sin límite (cupo del bus)

('INAPAM', 'Adulto Mayor con credencial vigente', 0.50, 2),
('Niño', 'Menores de 5 a 12 años', 0.50, 5), -- A veces limitado a 5 o ilimitado según temporada
('CONADIS', 'Personas con Discapacidad', 0.10, 2),

('Estudiante', 'Temporada Vacacional (Credencial Vigente)', 0.50, 3),
('Maestro', 'Temporada Vacacional (Credencial Vigente)', 0.25, 2),

('Compra Anticipada', 'Nivel 1 - Super Oferta Web', 0.50, 4),  
('Compra Anticipada', 'Nivel 2 - Oferta Alta', 0.40, 4),       
('Compra Anticipada', 'Nivel 3 - Oferta Media', 0.30, 6),      
('Compra Anticipada', 'Nivel 4 - Descuento Bajo', 0.15, 10),   
('Compra Anticipada', 'Nivel 5 - Descuento Mínimo', 0.10, 0),  


('Buen Fin', 'Promoción Anual - Tarjeta Crédito', 0.20, 0),
('Buen Fin', 'Promoción Anual - Oferta Relámpago', 0.40, 5),
('Hot Sale', 'Exclusivo Venta en Línea', 0.30, 10),

('Convenio Militar', 'SEDENA / Marina', 0.20, 5),
('Lealtad', 'Programa Viajero Frecuente', 0.10, 0),
('Convenio Bancario', 'Pago con Citibanamex/BBVA', 0.10, 0);