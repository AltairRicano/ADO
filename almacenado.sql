DO $$
DECLARE
    inicio INT := 1;
    fin    INT := 100;
BEGIN
    INSERT INTO asiento (numero_asiento, estado, descripcion, corrida_id)
    SELECT
        gs::VARCHAR AS numero_asiento, -- 1. Cast a VARCHAR
        CASE WHEN random() < 0.5 THEN 'Disponible' ELSE 'Ocupado' END AS estado,
        CASE WHEN random() < 0.5 THEN 'Pasillo' ELSE 'Ventana' END AS descripcion,
        c.corrida_id
    FROM (
        SELECT
            g AS corrida_id,
            -- 2. Cast del índice a INT
            (ARRAY[44, 40, 27])[floor(random()*3 + 1)::INT] AS capacidad
        FROM generate_series(inicio, fin) g
    ) AS c
    CROSS JOIN LATERAL generate_series(1, c.capacidad) AS gs;
END $$;