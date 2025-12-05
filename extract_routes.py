import json
import re

def load_terminal_map(sql_file_path):
    """
    Parses the SQL file to map terminal names to their IDs.
    Assumes IDs are sequential starting from 1 based on insertion order
    in the 'INSERT INTO terminal' section.
    """
    terminal_map = {}
    try:
        with open(sql_file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Find the INSERT INTO terminal section
        # Looking for: INSERT INTO terminal (nombre, ...) VALUES
        # Use non-greedy match (.*?) to stop at the first semicolon
        match = re.search(r"INSERT INTO terminal\s*\(.*?\)\s*VALUES\s*(.*?);", content, re.DOTALL | re.IGNORECASE)
        if not match:
            print("Error: Could not find 'INSERT INTO terminal' section in SQL file.")
            return {}
            
        values_block = match.group(1)
        
        # Regex to find values like ('Name', ...)
        # We assume 'nombre' is the first column as seen in the file: (nombre, direccion, ...)
        # The file format is: ('Nombre', 'Direccion', ...)
        # We need to be careful with quotes inside strings, but for now assuming standard SQL escaping
        
        # Splitting by lines or '),' might be safer given the formatting
        # The file has one tuple per line usually
        
        current_id = 1
        # Simple regex to capture the first string in the tuple
        # \s*\(\s*'([^']*)'
        value_pattern = re.compile(r"\s*\(\s*'([^']*)'")
        
        for line in values_block.split('\n'):
            line = line.strip()
            if not line or line.startswith('--'):
                continue
                
            m = value_pattern.match(line)
            if m:
                name = m.group(1)
                terminal_map[name] = current_id
                current_id += 1
                
    except FileNotFoundError:
        print(f"Error: File not found at {sql_file_path}")
        return {}

    return terminal_map

def find_terminal_id(name, terminal_map):
    """
    Tries to find a terminal ID by name.
    1. Exact match.
    2. Case-insensitive match.
    3. Substring match (if map key contains name).
    """
    if not name:
        return None
        
    # 1. Exact match
    if name in terminal_map:
        return terminal_map[name]
        
    name_lower = name.lower()
    
    # 2. Case-insensitive match
    for k, v in terminal_map.items():
        if k.lower() == name_lower:
            return v
            
    # 3. Substring match (map key contains name OR name contains map key)
    # e.g. name="Veracruz" matches key="Veracruz CAVE"
    # e.g. name="México TAPO Lujo" matches key="México TAPO"
    candidates = []
    for k, v in terminal_map.items():
        k_lower = k.lower()
        if name_lower in k_lower or k_lower in name_lower:
            candidates.append((k, v))
            
    if candidates:
        # Pick the one that starts with the name if possible, or the longest match?
        # If we have "México TAPO" (shorter) matching "México TAPO Lujo" (longer name),
        # we want to pick the key that is most similar.
        # Let's sort by length of the key, descending, to match the most specific key possible.
        # e.g. if we had "México" and "México TAPO", and name is "México TAPO Lujo",
        # "México TAPO" is a better match than "México".
        candidates.sort(key=lambda x: len(x[0]), reverse=True)
        return candidates[0][1]
        
    return None

def extract_routes(json_file_path, sql_file_path, output_sql_path):
    """
    Extracts unique routes from scraping.json and generates a single bulk SQL INSERT statement.
    """
    terminal_map = load_terminal_map(sql_file_path)
    if not terminal_map:
        print("No terminal mapping found. Aborting.")
        return

    try:
        with open(json_file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: File not found at {json_file_path}")
        return
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON format in {json_file_path}")
        return

    unique_routes = set()
    values_list = []

    items = data.get('results', {}).get('items', [])

    for item in items:
        # Skip items that are errors or missing required fields
        if item.get('_status') != 'ok' or '_code' in item:
            continue
        
        origen = item.get('origen')
        destino = item.get('destino')
        tipo_viaje = item.get('tipo de viaje')

        if not origen or not destino:
            continue
            
        # Create a unique key for the route
        route_key = (origen, destino, tipo_viaje)

        if route_key not in unique_routes:
            
            # Resolve IDs
            salida_id = find_terminal_id(origen, terminal_map)
            llegada_id = find_terminal_id(destino, terminal_map)
            
            if not salida_id:
                print(f"Warning: Terminal '{origen}' not found in map. Skipping route.")
                continue
            if not llegada_id:
                print(f"Warning: Terminal '{destino}' not found in map. Skipping route.")
                continue

            unique_routes.add(route_key)
            
            # Escaping single quotes in names just in case
            safe_origen = origen.replace("'", "''")
            safe_destino = destino.replace("'", "''")
            safe_tipo_viaje = tipo_viaje.replace("'", "''") if tipo_viaje else 'NULL'
            
            nombre_ruta = f"{safe_origen} - {safe_destino}"
            
            # (nombre, tipo_corrida, terminal_salida_id, terminal_llegada_id)
            values_list.append(f"('{nombre_ruta}', '{safe_tipo_viaje}', {salida_id}, {llegada_id})")

    if values_list:
        with open(output_sql_path, 'w', encoding='utf-8') as f:
            f.write("-- Generated SQL inserts for ruta table\n")
            f.write("INSERT INTO ruta (nombre, tipo_corrida, terminal_salida_id, terminal_llegada_id) VALUES\n")
            f.write(",\n".join(values_list))
            f.write(";\n")

        print(f"Successfully processed {len(items)} items.")
        print(f"Generated {len(values_list)} unique route inserts.")
        print(f"Output saved to {output_sql_path}")
    else:
        print("No valid routes found to insert.")

if __name__ == "__main__":
    input_json = 'scraping.json'
    input_sql = '01_estadoypoblacion.sql'
    output_sql = 'inserts_ruta.sql'
    extract_routes(input_json, input_sql, output_sql)
