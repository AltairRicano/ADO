DO $$
DECLARE
    inicio INT := 1;       -- Cambia estos valores por bloque
    fin    INT := 100;   -- 50,000 corridas por batch
BEGIN
    INSERT INTO asiento (numero_asiento, estado, descripcion, corrida_id)
    SELECT
        gs AS numero_asiento,
        CASE WHEN random() < 0.5 THEN 'Disponible' ELSE 'Ocupado' END AS estado,
        CASE WHEN random() < 0.5 THEN 'Pasillo' ELSE 'Ventana' END AS descripcion,
        c.corrida_id
    FROM (
        SELECT
            g AS corrida_id,
            (ARRAY[44, 40, 27])[floor(random()*3)+1] AS capacidad
        FROM generate_series(inicio, fin) g
    ) AS c
    CROSS JOIN LATERAL generate_series(1, c.capacidad) AS gs;

END $$;