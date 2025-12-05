import json
import time
import os
from playwright.sync_api import sync_playwright

# ================= CONFIGURACIÓN =================
ARCHIVO_TERMINALES = "terminals.json"
ARCHIVO_RUTAS_VALIDAS = "rutas_validas.json"

def asegurar_terminales_prueba():
    if not os.path.exists(ARCHIVO_TERMINALES):
        print(f"⚠️ {ARCHIVO_TERMINALES} no encontrado. Creando datos de ejemplo...")
        datos = {
            "terminals": [
                {"name": "Mexico City (Todas)", "slug": "mexico-ciudad-de-mexico"},
                {"name": "Puebla CAPU", "slug": "puebla-pue-capu"},
                {"name": "Veracruz", "slug": "veracruz-ver-cave"},
                {"name": "Cancun", "slug": "cancun-qroo"},
                {"name": "Merida", "slug": "merida-yuc-came"},
                {"name": "Oaxaca", "slug": "oaxaca-oax"}
            ]
        }
        with open(ARCHIVO_TERMINALES, 'w', encoding='utf-8') as f:
            json.dump(datos, f, indent=4)

def cargar_terminales():
    asegurar_terminales_prueba()
    try:
        with open(ARCHIVO_TERMINALES, 'r', encoding='utf-8') as f:
            data = json.load(f)
            if isinstance(data, dict): return data.get("terminals", [])
            elif isinstance(data, list): return data
            return []
    except: return []

def intentar_cerrar_popups(page):
    """Cierra anuncios o avisos de cookies."""
    for selector in ["button#onetrust-accept-btn-handler", ".close-icon", "[aria-label='Cerrar']"]:
        try:
            if page.is_visible(selector): page.click(selector)
        except: pass

def descubrir_rutas():
    terminales = cargar_terminales()
    rutas_validas = []
    
    if not terminales:
        print("❌ No hay terminales.")
        return

    print(f"🗺️  Iniciando mapeo para {len(terminales)} orígenes.")
    
    with sync_playwright() as p:
        # Configuración Anti-Bot
        browser = p.chromium.launch(
            headless=False, # Pon True si no quieres ver el navegador
            args=["--start-maximized", "--disable-blink-features=AutomationControlled"]
        )
        context = browser.new_context(
            viewport=None,
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
        )
        page = context.new_page()
        
        try:
            print("⏳ Cargando ADO...")
            page.goto("https://www.ado.com.mx/", timeout=60000)
            page.wait_for_load_state("domcontentloaded")
            time.sleep(4) # Espera a que desaparezca el loading inicial
            intentar_cerrar_popups(page)
        except Exception as e:
            print(f"❌ Error carga inicial: {e}")
            return

        for i, terminal_origen in enumerate(terminales):
            # Obtener nombre
            nombre = terminal_origen if isinstance(terminal_origen, str) else terminal_origen.get("name", "")
            if not nombre: continue

            print(f"📍 ({i+1}/{len(terminales)}) Origen: {nombre}")
            
            try:
                # 1. BUSCAR INPUT ORIGEN (Estrategia visual)
                # Playwright moderno: busca por el placeholder o texto visible
                input_origen = None
                
                # Intentos en orden de probabilidad
                if page.get_by_placeholder("Origen").is_visible():
                    input_origen = page.get_by_placeholder("Origen")
                elif page.locator("input[name='origin']").is_visible():
                    input_origen = page.locator("input[name='origin']")
                elif page.get_by_role("combobox", name="Origen").is_visible():
                    input_origen = page.get_by_role("combobox", name="Origen")
                
                # Si falló, tomamos foto y reintentamos
                if not input_origen:
                    print("   ⚠️ No veo la caja de Origen. Guardando foto 'debug_ado.png'...")
                    page.screenshot(path="debug_ado.png")
                    print("   🔄 Recargando página...")
                    page.reload()
                    time.sleep(5)
                    # Segundo intento
                    if page.get_by_placeholder("Origen").is_visible():
                        input_origen = page.get_by_placeholder("Origen")
                
                if not input_origen:
                    print("   ❌ IMPOSIBLE ENCONTRAR INPUT. (Revisa debug_ado.png)")
                    continue

                # 2. INTERACTUAR
                input_origen.click()
                page.keyboard.press("Control+A")
                page.keyboard.press("Backspace")
                time.sleep(0.5)
                
                # Escribir lento para engañar a React
                page.keyboard.type(nombre, delay=100)
                time.sleep(2.0) 
                page.keyboard.press("Enter")
                time.sleep(1)

                # 3. DESTINO
                # A veces el foco pasa solo, a veces no.
                try:
                    if page.get_by_placeholder("Destino").is_visible():
                        page.get_by_placeholder("Destino").click()
                    else:
                        page.keyboard.press("Tab")
                except: pass
                
                time.sleep(2) # Esperar lista desplegable

                # 4. LEER RESULTADOS
                opciones = []
                # Busca elementos de lista (dropdown)
                locators_lista = page.locator("ul[role='listbox'] li, .suggestion-item").all_inner_texts()
                
                for txt in locators_lista:
                    limpio = txt.split("\n")[0].strip()
                    if limpio and limpio != nombre:
                        rutas_validas.append({
                            "origin_name": nombre,
                            "destination_name": limpio,
                            "origin_slug": nombre.lower().replace(" ", "-"), # Slug simple
                            "destination_slug": limpio.lower().replace(" ", "-")
                        })

                print(f"   ✅ {len(locators_lista)} destinos encontrados.")

                # Recargar para limpiar
                page.goto("https://www.ado.com.mx/", timeout=30000)
                time.sleep(2)

            except Exception as e:
                print(f"   ❌ Error: {e}")
                # Si el navegador se cerró, paramos
                if "Target closed" in str(e): break
                try: page.goto("https://www.ado.com.mx/") 
                except: pass

        browser.close()

    # Guardar
    with open(ARCHIVO_RUTAS_VALIDAS, 'w', encoding='utf-8') as f:
        json.dump({"routes": rutas_validas}, f, indent=4)
    print(f"🏁 Listo. {len(rutas_validas)} rutas en {ARCHIVO_RUTAS_VALIDAS}")

if __name__ == "__main__":
    descubrir_rutas()