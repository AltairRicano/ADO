import re
import random
import difflib

# --- Configuration ---
ROUTE_FILES = ['09_ruta.sql', 'generated_complex_routes.sql']
FAVORITO_FILE = '14_favorito.sql'
CORTESIA_FILE = '16_cortesia.sql'

# --- Data Loading ---

def load_routes():
    routes = {}
    pattern = r"\(\s*(\d+),\s*'([^']+)',"
    
    for filepath in ROUTE_FILES:
        try:
            with open(filepath, 'r') as f:
                content = f.read()
                matches = re.findall(pattern, content)
                for m in matches:
                    rid = int(m[0])
                    name = m[1]
                    # Parse destination from "Origin - Destination"
                    parts = name.split(' - ')
                    dest = parts[-1].strip() if len(parts) > 1 else name
                    # Clean destination
                    dest = re.sub(r" (Viaje|local|de paso|Lujo|CAXA|TAPO|CAPU).*", "", dest, flags=re.IGNORECASE).strip()
                    
                    routes[rid] = {
                        'name': name,
                        'dest': dest
                    }
        except FileNotFoundError:
            print(f"Warning: {filepath} not found.")
            
    print(f"Loaded {len(routes)} routes.")
    return routes

def find_route_by_dest(routes, target_dest):
    # Try exact match
    candidates = [rid for rid, r in routes.items() if r['dest'].lower() == target_dest.lower()]
    if candidates:
        return random.choice(candidates)
    
    # Try partial match
    candidates = [rid for rid, r in routes.items() if target_dest.lower() in r['dest'].lower() or r['dest'].lower() in target_dest.lower()]
    if candidates:
        return random.choice(candidates)
        
    return None

def fix_favorito(routes):
    print("Fixing Favorito...")
    valid_ids = list(routes.keys())
    if not valid_ids:
        print("No valid routes found!")
        return

    with open(FAVORITO_FILE, 'r') as f:
        lines = f.readlines()
        
    new_lines = []
    # Pattern: ('Nombre', 'Fecha', RutaID, CuentaID)
    # Note: RutaID is the 3rd value.
    # Example: ('Casa Mamá', '2025-03-12 12:04:54', 5741, 138617),
    pattern = r"^\s*\('([^']+)',\s*'([^']+)',\s*(\d+),\s*(\d+)\)(,?|;)"
    
    for line in lines:
        match = re.search(pattern, line)
        if match:
            name = match.group(1)
            date = match.group(2)
            old_rid = match.group(3)
            acc_id = match.group(4)
            ender = match.group(5)
            
            # Try to find matching route
            new_rid = find_route_by_dest(routes, name)
            
            if not new_rid:
                # Random fallback
                new_rid = random.choice(valid_ids)
                
            new_line = f"('{name}', '{date}', {new_rid}, {acc_id}){ender}\n"
            new_lines.append(new_line)
        else:
            new_lines.append(line)
            
    with open(FAVORITO_FILE, 'w') as f:
        f.writelines(new_lines)
    print(f"Updated {FAVORITO_FILE}")

def fix_cortesia(routes):
    print("Fixing Cortesia...")
    valid_ids = list(routes.keys())
    if not valid_ids:
        return

    with open(CORTESIA_FILE, 'r') as f:
        lines = f.readlines()
        
    new_lines = []
    # Pattern: ('Nombre', 'Direccion', 'CP', 'Open', 'Close', RutaID)
    # Example: ('Alterna galerías', 'Av. Pedro Saiz de Baranda', '02401', '09:00:00', '21:00:00', 2),
    pattern = r"^\s*\('([^']+)',\s*'([^']+)',\s*'([^']*)',\s*'([^']+)',\s*'([^']+)',\s*(\d+)\)(,?|;)"
    
    current_state = ""
    
    for line in lines:
        if line.strip().startswith("--"):
            current_state = line.strip().replace("--", "").strip()
            new_lines.append(line)
            continue
            
        match = re.search(pattern, line)
        if match:
            name = match.group(1)
            addr = match.group(2)
            cp = match.group(3)
            open_t = match.group(4)
            close_t = match.group(5)
            old_rid = match.group(6)
            ender = match.group(7)
            
            # Try to find route by State or Name
            # We can try to match State name in Route Name
            target = current_state if current_state else name
            
            # Heuristic: Map states to likely route keywords
            # CAMPECHE -> Carmen, Campeche
            # CHIAPAS -> Tuxtla, Tapachula, San Cristobal
            # VERACRUZ -> Veracruz, Xalapa, Coatzacoalcos, Minatitlan
            # PUEBLA -> Puebla
            # TABASCO -> Villahermosa
            # OAXACA -> Oaxaca
            # QUINTANA ROO -> Cancun, Chetumal, Playa
            # YUCATAN -> Merida
            
            keywords = [target, name]
            if "CAMPECHE" in current_state: keywords.extend(["Carmen", "Campeche"])
            if "CHIAPAS" in current_state: keywords.extend(["Tuxtla", "Tapachula", "Cristobal"])
            if "VERACRUZ" in current_state: keywords.extend(["Veracruz", "Xalapa", "Coatzacoalcos", "Minatitlán", "Orizaba", "Cordoba"])
            if "PUEBLA" in current_state: keywords.extend(["Puebla", "Tehuacán"])
            if "TABASCO" in current_state: keywords.extend(["Villahermosa"])
            if "OAXACA" in current_state: keywords.extend(["Oaxaca"])
            if "QUINTANA" in current_state: keywords.extend(["Cancún", "Chetumal", "Playa"])
            if "YUCATAN" in current_state: keywords.extend(["Mérida"])
            if "MÉXICO" in current_state or "MEXICO" in current_state: keywords.extend(["México", "TAPO", "Norte"])
            
            new_rid = None
            for kw in keywords:
                candidates = [rid for rid, r in routes.items() if kw.lower() in r['name'].lower()]
                if candidates:
                    new_rid = random.choice(candidates)
                    break
            
            if not new_rid:
                new_rid = random.choice(valid_ids)
                
            new_line = f"('{name}', '{addr}', '{cp}', '{open_t}', '{close_t}', {new_rid}){ender}\n"
            new_lines.append(new_line)
        else:
            new_lines.append(line)
            
    with open(CORTESIA_FILE, 'w') as f:
        f.writelines(new_lines)
    print(f"Updated {CORTESIA_FILE}")

if __name__ == "__main__":
    routes = load_routes()
    fix_favorito(routes)
    fix_cortesia(routes)
