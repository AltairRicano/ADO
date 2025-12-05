import random

# ==========================================
# CONFIGURACIÓN
# ==========================================
FILENAME = "11_ruta.sql"

# IDs de Terminales (Rangos aproximados según tus scripts anteriores)
# CDMX: 1-9, EDOMEX: 10-17, PUEBLA: 18-28, HIDALGO: 29-34
# VERACRUZ: 57-85, TABASCO: 82 (Hub), OAXACA: 100-115, CHIAPAS: 117-131
# QROO: 153-163, YUCATAN: 142-152

# Definimos listas simples de IDs por estado para generar conexiones lógicas
terminales_por_zona = {
    "Centro": list(range(1, 18)),   # CDMX, Edomex
    "Puebla": list(range(18, 29)),
    "Golfo": list(range(57, 86)),   # Veracruz
    "Sur": list(range(82, 92)),     # Tabasco
    "Sureste": list(range(101, 123)) # Yucatán, Q.Roo
}

# Hubs principales para rutas maestras
hubs = [1, 18, 57, 82, 101, 112] 

valores_sql = []
ruta_id = 1

print("Generando catálogo de rutas (Sin distancia)...")

# 1. GENERAR RUTAS LOCALES (Intra-zona)
# Conectamos terminales cercanas entre sí
for zona, ids in terminales_por_zona.items():
    # Hacemos un muestreo para no hacer "todos contra todos" (serían demasiadas)
    # Conectamos cada terminal con otras 3 aleatorias de su misma zona
    for t1 in ids:
        destinos = random.sample([x for x in ids if x != t1], k=min(len(ids)-1, 3))
        for t2 in destinos:
            nombre = f"Ruta Local {t1}-{t2}"
            # (ruta_id, nombre, tipo_corrida, terminal_salida, terminal_llegada)
            val = f"({ruta_id}, '{nombre}', 'Local', {t1}, {t2})"
            valores_sql.append(val)
            ruta_id += 1

# 2. GENERAR RUTAS MAESTRAS (Inter-zona)
# Conectamos los Hubs entre sí (Ida y Vuelta)
for h1 in hubs:
    for h2 in hubs:
        if h1 != h2:
            nombre = f"Ruta Maestra Directa {h1}-{h2}"
            val = f"({ruta_id}, '{nombre}', 'Maestra', {h1}, {h2})"
            valores_sql.append(val)
            ruta_id += 1

# ==========================================
# ESCRITURA DEL ARCHIVO SQL
# ==========================================
print(f"Escribiendo {len(valores_sql)} rutas en {FILENAME}...")

with open(FILENAME, "w", encoding="utf-8") as f:
    f.write("-- CATÁLOGO DE RUTAS (Sin Distancia)\n")
    f.write("INSERT INTO ruta (ruta_id, nombre, tipo_corrida, terminal_salida_id, terminal_llegada_id) VALUES\n")
    f.write(",\n".join(valores_sql))
    f.write(";\n")

print("¡Listo!")