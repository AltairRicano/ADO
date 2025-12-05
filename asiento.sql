CREATE TABLE asiento (
    asiento_id SERIAL PRIMARY KEY,
    numero_asiento VARCHAR(4) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Disponible',
    descripcion VARCHAR(50) NOT NULL,
    corrida_id INT NOT NULL,
    CONSTRAINT fk_corrida_id FOREIGN KEY (corrida_id) REFERENCES corrida(corrida_id)
);
