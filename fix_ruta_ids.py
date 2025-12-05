import re

ROUTE_FILE = '09_ruta.sql'
START_ID = 200

def fix_ids():
    with open(ROUTE_FILE, 'r') as f:
        lines = f.readlines()
        
    new_lines = []
    # Pattern: ('Name', 'Type', ID1, ID2)
    # We want to change it to: (NEW_ID, 'Name', 'Type', ID1, ID2)
    # And update the INSERT statement to include ruta_id
    
    # Regex to match the values line
    # ('México TAPO - Veracruz', 'local', 23, 94)
    pattern = r"^\s*\('([^']+)',\s*'([^']+)',\s*(\d+),\s*(\d+)\)(,?|;)"
    
    current_id = START_ID
    
    for line in lines:
        if "INSERT INTO ruta" in line:
            # Update the INSERT statement
            new_line = line.replace(
                "(nombre, tipo_corrida, terminal_salida_id, terminal_llegada_id)",
                "(ruta_id, nombre, tipo_corrida, terminal_salida_id, terminal_llegada_id)"
            )
            new_lines.append(new_line)
            continue
            
        match = re.search(pattern, line)
        if match:
            name = match.group(1)
            rtype = match.group(2)
            t1 = match.group(3)
            t2 = match.group(4)
            ender = match.group(5)
            
            new_line = f"({current_id}, '{name}', '{rtype}', {t1}, {t2}){ender}\n"
            new_lines.append(new_line)
            current_id += 1
        else:
            new_lines.append(line)
            
    with open(ROUTE_FILE, 'w') as f:
        f.writelines(new_lines)
    print(f"Updated {ROUTE_FILE} with IDs starting from {START_ID}")

if __name__ == "__main__":
    fix_ids()
