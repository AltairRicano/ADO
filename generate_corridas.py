import re
import sys
import random
from datetime import datetime, timedelta
import time
import os

# --- Configuration ---
START_DATE = datetime(2025, 9, 1)
TARGET_RECORDS = 300000
OUTPUT_FILE = "generated_corridas.sql"
SLEEP_INTERVAL_LINES = 1000  # Sleep every N lines generated
SLEEP_DURATION = 0.05        # Seconds to sleep
ROUTE_FILES = ['09_ruta.sql', 'generated_complex_routes.sql'] # Added ROUTE_FILES

# --- Data Loading Functions ---

def load_routes():
    """Loads routes from SQL files."""
    routes = []
    # Pattern for routes with explicit ID: (ID, 'Name', 'Type', ...)
    pattern_explicit = r"\(\s*(\d+),\s*'([^']+)',"
    # Pattern for routes without explicit ID: ('Name', 'Type', ...)
    pattern_implicit = r"\(\s*'([^']+)',\s*'([^']+)',"

    current_implicit_id = 1

    for filepath in ROUTE_FILES:
        if not os.path.exists(filepath):
            print(f"Warning: {filepath} not found.")
            continue
            
        with open(filepath, 'r') as f:
            content = f.read()
            
            # Try explicit first
            matches_explicit = re.findall(pattern_explicit, content)
            if matches_explicit:
                for m in matches_explicit:
                    routes.append({
                        'id': int(m[0]),
                        'name': m[1]
                    })
            else:
                # Try implicit
                matches_implicit = re.findall(pattern_implicit, content)
                for m in matches_implicit:
                    routes.append({
                        'id': current_implicit_id,
                        'name': m[0]
                    })
                    current_implicit_id += 1
                    
    print(f"Loaded {len(routes)} routes.")
    return routes

def load_vehicles(filepath):
    vehicles = []
    # (matricula, marca_id, modelo, asientos, estado)
    # We need to simulate the IDs. Assuming they start at 1 and increment.
    
    try:
        with open(filepath, 'r') as f:
            content = f.read()
            
        # Regex to match values inside VALUES (...)
        pattern = r"\('([^']+)',\s*(\d+),\s*'([^']+)',\s*(\d+),\s*'([^']+)'\)"
        matches = re.findall(pattern, content)
        
        for i, m in enumerate(matches):
            vehicles.append({
                'id': i + 1, # Simulated ID
                'matricula': m[0],
                'marca_id': int(m[1]),
                'modelo': m[2],
                'asientos': int(m[3]),
                'estado': m[4]
            })
            
    except FileNotFoundError:
        print(f"Error: File {filepath} not found.")
        return []
    return vehicles

def load_drivers(filepath):
    drivers = []
    # INSERT INTO chofer (chofer_id, ...) VALUES (2, ...)
    try:
        with open(filepath, 'r') as f:
            content = f.read()
            
        pattern = r"\((\d+),\s*'[^']+',\s*'([^']+)'"
        matches = re.findall(pattern, content)
        
        for m in matches:
            drivers.append({
                'id': int(m[0]),
                'estado': m[1]
            })
            
    except FileNotFoundError:
        print(f"Error: File {filepath} not found.")
        return []
    return drivers

def load_brands(filepath):
    brands = {}
    # (1, 'ADO Mobility', 'Primera')
    try:
        with open(filepath, 'r') as f:
            content = f.read()
            
        pattern = r"\((\d+),\s*'[^']+',\s*'([^']+)'\)"
        matches = re.findall(pattern, content)
        
        for m in matches:
            brands[int(m[0])] = m[1] # ID -> Tipo Servicio
            
    except FileNotFoundError:
        print(f"Error: File {filepath} not found.")
        return {}
    return brands


# --- Helper Functions ---

def get_cost_factor(service_type):
    if 'Platino' in service_type or 'Lujo' in service_type:
        return 2.0
    elif 'GL' in service_type or 'Ejecutivo' in service_type:
        return 1.5
    elif 'Aeropuerto' in service_type:
        return 1.3
    else: # Primera, Conecta, etc.
        return 1.0

def estimate_duration(route_name):
    # Random between 2 and 12 hours for variety.
    return timedelta(hours=random.uniform(2, 12))

# --- Main Generation Logic ---

def generate_corridas():
    # Load Data
    print("Loading data...")
    routes = load_routes()
    vehicles = load_vehicles('08_vehiculo.sql')
    drivers = load_drivers('05_choferes.sql')
    brands = load_brands('02_marca-amenidad.sql')
    
    print(f"Loaded {len(routes)} routes, {len(vehicles)} vehicles, {len(drivers)} drivers, {len(brands)} brands.")
    
    if not routes or not vehicles or not drivers:
        print("Critical data missing. Aborting.")
        return

    # Filter for active resources
    active_vehicles = [v for v in vehicles if v['estado'] == 'Servicio']
    active_drivers = [d for d in drivers if d['estado'] in ['Disponible', 'En_Ruta']]
    
    print(f"Active resources: {len(active_vehicles)} vehicles, {len(active_drivers)} drivers.")

    # Schedule State
    # {id: available_datetime}
    vehicle_availability = {v['id']: START_DATE for v in active_vehicles}
    driver_availability = {d['id']: START_DATE for d in active_drivers}
    
    sql_statements = []
    sql_statements.append("-- Generated Corridas")
    sql_statements.append("INSERT INTO corrida (fecha_hora_salida, fecha_hora_llegada, costo_base, ruta_id, chofer_id, vehiculo_id) VALUES")
    
    current_date = START_DATE
    total_corridas = 0
    buffer_time = timedelta(hours=2) # Time between trips for maintenance/rest
    
    print(f"Starting generation. Target: {TARGET_RECORDS} records.")
    
    while total_corridas < TARGET_RECORDS:
        # Increase density: Run ALL routes every day, multiple times
        # To reach 300k faster, we need high volume.
        # Let's try to schedule 3-6 trips for EVERY route each day
        
        daily_routes = routes # All routes
        
        for route in daily_routes:
            if total_corridas >= TARGET_RECORDS:
                break

            # Higher density: 3 to 6 trips per route per day
            num_trips = random.randint(3, 6)
            
            for _ in range(num_trips):
                if total_corridas >= TARGET_RECORDS:
                    break

                # Determine departure time (random within the day)
                hour = random.randint(5, 23) # 5 AM to 11 PM
                minute = random.choice([0, 15, 30, 45])
                departure_time = current_date.replace(hour=hour, minute=minute)
                
                duration = estimate_duration(route['name'])
                arrival_time = departure_time + duration
                
                # Find available vehicle
                selected_vehicle = None
                # Optimization: Don't shuffle full list every time, it's slow.
                # Just pick a random start index and search
                start_idx = random.randint(0, len(active_vehicles)-1)
                for i in range(len(active_vehicles)):
                    idx = (start_idx + i) % len(active_vehicles)
                    v = active_vehicles[idx]
                    if vehicle_availability[v['id']] <= departure_time:
                        selected_vehicle = v
                        break
                
                if not selected_vehicle:
                    continue # No vehicle available for this slot
                
                # Find available driver
                selected_driver = None
                start_idx = random.randint(0, len(active_drivers)-1)
                for i in range(len(active_drivers)):
                    idx = (start_idx + i) % len(active_drivers)
                    d = active_drivers[idx]
                    if driver_availability[d['id']] <= departure_time:
                        selected_driver = d
                        break
                        
                if not selected_driver:
                    continue # No driver available
                
                # Calculate Cost
                service_type = brands.get(selected_vehicle['marca_id'], 'Primera')
                cost_factor = get_cost_factor(service_type)
                # Base cost: $100 per hour * factor
                cost = round((duration.total_seconds() / 3600) * 100 * cost_factor, 2)
                
                # Update Availability
                vehicle_availability[selected_vehicle['id']] = arrival_time + buffer_time
                driver_availability[selected_driver['id']] = arrival_time + buffer_time
                
                # Generate SQL
                values = f"('{departure_time}', '{arrival_time}', {cost}, {route['id']}, {selected_driver['id']}, {selected_vehicle['id']})"
                sql_statements.append(values)
                total_corridas += 1
                
                if total_corridas % SLEEP_INTERVAL_LINES == 0:
                    time.sleep(SLEEP_DURATION)
                    print(f"Generated {total_corridas} corridas... Current Date: {current_date.date()}")

        current_date += timedelta(days=1)
        
    # Format output
    batch_size = 1000
    final_sql = []
    
    header = "INSERT INTO corrida (fecha_hora_salida, fecha_hora_llegada, costo_base, ruta_id, chofer_id, vehiculo_id) VALUES"
    
    # Skip the first 2 lines (comment and header) from sql_statements list
    raw_values = sql_statements[2:] 
    
    for i in range(0, len(raw_values), batch_size):
        batch = raw_values[i:i+batch_size]
        final_sql.append(header)
        final_sql.append(",\n".join(batch) + ";")
        
    print(f"Writing {total_corridas} corridas to {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, 'w') as f:
        f.write("\n".join(final_sql))
        
    print("Done.")

if __name__ == "__main__":
    generate_corridas()
