#!/bin/bash

# 1. Definir nombre del contenedor y base de datos
CONTAINER="ado_db_server"
USER="equipo_ado"
DB="ado_produccion"

# 2. Mensaje de inicio
echo "🚀 INICIANDO DESPLIEGUE MASIVO..."

# 3. LA ESTRATEGIA DEL CAT (La más segura para Docker)
# Concatenamos todos los archivos en orden y los enviamos al tubo de Docker.
# ¡El orden importa muchísimo!

cat \
  00_ado_database.sql \
  01_estadoypoblacion.sql \
  02_marca-amenidad.sql \
  03_descuento.sql \
  04_empleados.sql \
  05_choferes.sql \
  06_cliente.sql \
  07_cuenta.sql \
  08_vehiculo.sql \
  09_ruta.sql \
  10_escala.sql \
  12_pasajero.sql \
  13_saldomax.sql \
  14_favorito.sql \
  15_corrida.sql \
  16_cortesia.sql \
  | docker exec -i $CONTAINER psql -U $USER -d $DB

# 4. Mensaje final
echo "✅ ¡DESPLIEGUE COMPLETADO!"