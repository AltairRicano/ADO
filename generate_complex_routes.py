import re
import sys

def parse_sql_file(filepath):
    try:
        with open(filepath, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: File {filepath} not found.")
        return []

    # Regex to capture values: ('Name', 'Type', Start, End)
    # Handles potential spaces and different quote types if necessary, but simple quotes are used in the file.
    pattern = r"\('([^']+)',\s*'([^']+)',\s*(\d+),\s*(\d+)\)"
    matches = re.findall(pattern, content)
    
    routes = []
    for i, m in enumerate(matches):
        routes.append({
            'id': i + 1, # Assuming sequential IDs starting at 1
            'nombre': m[0],
            'tipo': m[1],
            'salida': int(m[2]),
            'llegada': int(m[3])
        })
    return routes

def generate_combinations(routes):
    # Map start_id -> list of routes
    routes_by_start = {}
    for r in routes:
        if r['salida'] not in routes_by_start:
            routes_by_start[r['salida']] = []
        routes_by_start[r['salida']].append(r)
        
    combinations = []
    seen_combinations = set() # To avoid duplicates if multiple routes have same terminals
    
    # Length 2
    for r1 in routes:
        if r1['llegada'] in routes_by_start:
            for r2 in routes_by_start[r1['llegada']]:
                # Avoid loops
                if r2['llegada'] == r1['salida']:
                    continue
                
                # Construct name
                try:
                    origin = r1['nombre'].split(' - ')[0]
                    destination = r2['nombre'].split(' - ')[-1]
                    name = f"{origin} - {destination}"
                except:
                    name = f"Ruta Compleja {r1['salida']}-{r2['llegada']}"

                combo_key = (r1['id'], r2['id'])
                if combo_key in seen_combinations:
                    continue
                seen_combinations.add(combo_key)

                combo = {
                    'segments': [r1, r2],
                    'salida': r1['salida'],
                    'llegada': r2['llegada'],
                    'nombre': name
                }
                combinations.append(combo)
                
                # Length 3
                if r2['llegada'] in routes_by_start:
                    for r3 in routes_by_start[r2['llegada']]:
                        if r3['llegada'] == r1['salida'] or r3['llegada'] == r2['salida']:
                            continue
                        
                        try:
                            origin = r1['nombre'].split(' - ')[0]
                            destination = r3['nombre'].split(' - ')[-1]
                            name = f"{origin} - {destination}"
                        except:
                            name = f"Ruta Compleja {r1['salida']}-{r3['llegada']}"

                        combo_key_3 = (r1['id'], r2['id'], r3['id'])
                        if combo_key_3 in seen_combinations:
                            continue
                        seen_combinations.add(combo_key_3)

                        combo3 = {
                            'segments': [r1, r2, r3],
                            'salida': r1['salida'],
                            'llegada': r3['llegada'],
                            'nombre': name
                        }
                        combinations.append(combo3)
                        
    return combinations

def generate_sql(child_routes, combinations, start_parent_id):
    sql = []
    
    sql.append("-- Generated Parent Routes")
    sql.append("INSERT INTO ruta (ruta_id, nombre, tipo_corrida, terminal_salida_id, terminal_llegada_id) VALUES")
    
    parent_values = []
    escala_values = []
    
    current_id = start_parent_id
    
    for combo in combinations:
        parent_id = current_id
        current_id += 1
        
        name = combo['nombre']
        # Escape single quotes in name if present
        name = name.replace("'", "''")
        
        parent_values.append(f"({parent_id}, '{name}', 'De Paso', {combo['salida']}, {combo['llegada']})")
        
        for idx, segment in enumerate(combo['segments']):
            escala_values.append(f"({parent_id}, {segment['id']}, {idx + 1})")
            
    sql.append(",\n".join(parent_values) + ";")
    sql.append("")
    sql.append("-- Generated Escala Relationships")
    sql.append("INSERT INTO escala (ruta_padre_id, ruta_hijo_id, orden) VALUES")
    sql.append(",\n".join(escala_values) + ";")
    
    return "\n".join(sql)

if __name__ == "__main__":
    input_file = "09_ruta.sql"
    
    # Parse routes
    routes = parse_sql_file(input_file)
    print(f"Found {len(routes)} child routes.")
    
    if not routes:
        sys.exit(1)

    # Generate combinations
    combinations = generate_combinations(routes)
    print(f"Generated {len(combinations)} parent routes.")
    
    # Start ID for parent routes
    # Assuming child routes are 1..N
    start_parent_id = len(routes) + 1
    
    # Generate SQL
    sql_output = generate_sql(routes, combinations, start_parent_id)
    
    # Write to file or print
    output_file = "generated_complex_routes.sql"
    with open(output_file, 'w') as f:
        f.write(sql_output)
        
    print(f"SQL written to {output_file}")
