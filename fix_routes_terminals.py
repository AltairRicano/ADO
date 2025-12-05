import re
import difflib

TERMINAL_FILE = '01_estadoypoblacion.sql'
ROUTE_FILE = '09_ruta.sql'

def load_terminals():
    terminals = {}
    current_id = 1
    
    with open(TERMINAL_FILE, 'r') as f:
        content = f.read()
        
    # Find the INSERT INTO terminal block
    # It starts with INSERT INTO terminal ... VALUES
    # and ends with ;
    
    # We can regex for the values
    # ('Name', 'Address', 'CP', 'Open', 'Close', PoblacionID)
    # Note: Address can contain commas!
    # Regex: \('([^']+)',\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*(\d+)\)
    
    pattern = r"\('([^']+)',\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*(\d+)\)"
    
    # We need to be careful not to match 'parada_cortesia' or 'poblacion'
    # 'poblacion' has 3 fields: (id, name, state_id)
    # 'parada_cortesia' has 6 fields but starts later.
    # 'terminal' has 6 fields.
    
    # Let's split the file to isolate INSERT INTO terminal
    parts = content.split('INSERT INTO terminal')
    if len(parts) < 2:
        print("Could not find INSERT INTO terminal")
        return {}
        
    terminal_block = parts[1].split(';')[0]
    
    matches = re.findall(pattern, terminal_block)
    for m in matches:
        name = m[0]
        terminals[name.lower()] = current_id
        current_id += 1
        
    print(f"Loaded {len(terminals)} terminals.")
    return terminals

def find_terminal_id(terminals, name):
    name = name.lower().strip()
    if name in terminals:
        return terminals[name]
    
    # Try fuzzy match
    # Common variations: "Veracruz" -> "Veracruz CAVE", "México TAPO" -> "México TAPO"
    # "Central México Norte" -> "Central México Norte"
    
    # Try removing "Central" or "Terminal"
    clean_name = name.replace('central', '').replace('terminal', '').strip()
    if clean_name in terminals:
        return terminals[clean_name]
        
    # Try finding a terminal that CONTAINS the name
    candidates = [tid for tname, tid in terminals.items() if name in tname or tname in name]
    if candidates:
        # Prefer exact containment
        return candidates[0]
        
    # Difflib
    matches = difflib.get_close_matches(name, terminals.keys(), n=1, cutoff=0.6)
    if matches:
        return terminals[matches[0]]
        
    return None

def fix_routes(terminals):
    with open(ROUTE_FILE, 'r') as f:
        lines = f.readlines()
        
    new_lines = []
    # Pattern: ('Name', 'Type', ID1, ID2)
    # Example: ('México TAPO - Veracruz', 'local', 23, 94),
    pattern = r"^\s*\('([^']+)',\s*'([^']+)',\s*(\d+),\s*(\d+)\)(,?|;)"
    
    for line in lines:
        match = re.search(pattern, line)
        if match:
            full_name = match.group(1)
            rtype = match.group(2)
            old_t1 = match.group(3)
            old_t2 = match.group(4)
            ender = match.group(5)
            
            # Parse Origin - Destination
            if ' - ' in full_name:
                parts = full_name.split(' - ')
                origin_name = parts[0].strip()
                dest_name = parts[-1].strip() # Take last part in case of multiple dashes? usually just 2
            else:
                # Fallback?
                origin_name = full_name
                dest_name = full_name
            
            # Clean names (remove "Lujo", "Viaje", etc if they are part of the route name but not terminal name)
            # Actually, usually route name IS "Origin - Destination"
            
            new_t1 = find_terminal_id(terminals, origin_name)
            new_t2 = find_terminal_id(terminals, dest_name)
            
            if not new_t1: 
                print(f"Could not find terminal for origin: {origin_name}")
                new_t1 = 1 # Fallback
            if not new_t2: 
                print(f"Could not find terminal for dest: {dest_name}")
                new_t2 = 1 # Fallback
                
            new_line = f"('{full_name}', '{rtype}', {new_t1}, {new_t2}){ender}\n"
            new_lines.append(new_line)
        else:
            new_lines.append(line)
            
    with open(ROUTE_FILE, 'w') as f:
        f.writelines(new_lines)
    print(f"Updated {ROUTE_FILE}")

if __name__ == "__main__":
    terminals = load_terminals()
    fix_routes(terminals)
