ALTER TABLE poblacion ADD CONSTRAINT fk_poblacion_estado FOREIGN KEY (estado_id) REFERENCES estado(estado_id);
ALTER TABLE terminal ADD CONSTRAINT fk_terminal_poblacion FOREIGN KEY (poblacion_id) REFERENCES poblacion(poblacion_id);

ALTER TABLE ruta ADD CONSTRAINT fk_ruta_salida FOREIGN KEY (terminal_salida_id) REFERENCES terminal(terminal_id);
ALTER TABLE ruta ADD CONSTRAINT fk_ruta_llegada FOREIGN KEY (terminal_llegada_id) REFERENCES terminal(terminal_id);

ALTER TABLE escala ADD CONSTRAINT fk_escala_padre FOREIGN KEY (ruta_padre_id) REFERENCES ruta(ruta_id);
ALTER TABLE escala ADD CONSTRAINT fk_escala_hijo FOREIGN KEY (ruta_hijo_id) REFERENCES ruta(ruta_id);

ALTER TABLE corrida ADD CONSTRAINT fk_corrida_ruta FOREIGN KEY (ruta_id) REFERENCES ruta(ruta_id);
ALTER TABLE corrida ADD CONSTRAINT fk_corrida_chofer FOREIGN KEY (chofer_id) REFERENCES chofer(chofer_id);
ALTER TABLE corrida ADD CONSTRAINT fk_corrida_vehiculo FOREIGN KEY (vehiculo_id) REFERENCES vehiculo(vehiculo_id);

ALTER TABLE chofer ADD CONSTRAINT fk_chofer_empleado FOREIGN KEY (chofer_id) REFERENCES empleado(empleado_id);
ALTER TABLE vehiculo ADD CONSTRAINT fk_vehiculo_marca FOREIGN KEY (marca_id) REFERENCES marca(marca_id);

ALTER TABLE marca_amenidad ADD CONSTRAINT fk_marca_amenidad_marca FOREIGN KEY (marca_id) REFERENCES marca(marca_id);
ALTER TABLE marca_amenidad ADD CONSTRAINT fk_marca_amenidad_amenidad FOREIGN KEY (amenidad_id) REFERENCES amenidad(amenidad_id);

ALTER TABLE asiento ADD CONSTRAINT fk_asiento_corrida FOREIGN KEY (corrida_id) REFERENCES corrida(corrida_id);

ALTER TABLE cuenta ADD CONSTRAINT fk_cuenta_cliente FOREIGN KEY (cliente_id) REFERENCES cliente(cliente_id);
ALTER TABLE pasajero ADD CONSTRAINT fk_pasajero_cuenta FOREIGN KEY (cuenta_id) REFERENCES cuenta(cuenta_id);
ALTER TABLE favorito ADD CONSTRAINT fk_favorito_cuenta FOREIGN KEY (cuenta_id) REFERENCES cuenta(cuenta_id);
ALTER TABLE favorito ADD CONSTRAINT fk_favorito_ruta FOREIGN KEY (ruta_id) REFERENCES ruta(ruta_id);
ALTER TABLE saldo_max ADD CONSTRAINT fk_saldo_max_cliente FOREIGN KEY (cliente_id) REFERENCES cliente(cliente_id);

ALTER TABLE carrito ADD CONSTRAINT fk_carrito_cuenta FOREIGN KEY (cuenta_id) REFERENCES cuenta(cuenta_id) ON DELETE CASCADE;
ALTER TABLE detalle_carrito ADD CONSTRAINT fk_detalle_carrito_padre FOREIGN KEY (carrito_id) REFERENCES carrito(carrito_id) ON DELETE CASCADE;
ALTER TABLE detalle_carrito ADD CONSTRAINT fk_detalle_carrito_descuento FOREIGN KEY (descuento_id) REFERENCES descuento(descuento_id);

ALTER TABLE operacion ADD CONSTRAINT fk_operacion_cliente FOREIGN KEY (cliente_id) REFERENCES cliente(cliente_id);
ALTER TABLE detalle_operacion ADD CONSTRAINT fk_detalle_operacion_padre FOREIGN KEY (numero_operacion) REFERENCES operacion(numero_operacion);
ALTER TABLE metodo_pago ADD CONSTRAINT fk_metodo_pago_detalle FOREIGN KEY (detalle_operacion_id) REFERENCES detalle_operacion(detalle_operacion_id);

ALTER TABLE paypal ADD CONSTRAINT fk_paypal_metodo FOREIGN KEY (pago_id) REFERENCES metodo_pago(pago_id);
ALTER TABLE tarjeta ADD CONSTRAINT fk_tarjeta_metodo FOREIGN KEY (pago_id) REFERENCES metodo_pago(pago_id);
ALTER TABLE efectivo ADD CONSTRAINT fk_efectivo_metodo FOREIGN KEY (pago_id) REFERENCES metodo_pago(pago_id);
ALTER TABLE paynet ADD CONSTRAINT fk_paynet_efectivo FOREIGN KEY (pago_id) REFERENCES efectivo(pago_id);

ALTER TABLE detalle_saldo_max ADD CONSTRAINT fk_detalle_saldo_pago FOREIGN KEY (pago_id) REFERENCES metodo_pago(pago_id);
ALTER TABLE detalle_saldo_max ADD CONSTRAINT fk_detalle_saldo_billetera FOREIGN KEY (saldo_max_id) REFERENCES saldo_max(saldo_max_id);

ALTER TABLE boleto ADD CONSTRAINT fk_boleto_asiento FOREIGN KEY (asiento_id) REFERENCES asiento(asiento_id);
ALTER TABLE boleto ADD CONSTRAINT fk_boleto_operacion FOREIGN KEY (numero_operacion) REFERENCES operacion(numero_operacion);
ALTER TABLE boleto ADD CONSTRAINT fk_boleto_descuento FOREIGN KEY (descuento_id) REFERENCES descuento(descuento_id);

ALTER TABLE factura ADD CONSTRAINT fk_factura_boleto FOREIGN KEY (numero_folio) REFERENCES boleto(numero_folio);