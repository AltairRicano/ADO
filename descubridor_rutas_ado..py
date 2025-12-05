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
    posibles_botones = [
        "button#onetrust-accept-btn-handler", 
        ".close-icon", 
        "[aria-label='Cerrar']",
        "button:has-text('Aceptar cookies')",
        "button:has-text('Entendido')"
    ]
    for selector in posibles_botones:
        try:
            if page.is_visible(selector): 
                page.click(selector)
                time.sleep(0.5)
        except: pass

def descubrir_rutas():
    terminales = cargar_terminales()
    rutas_validas = []
    
    if not terminales:
        print("❌ No hay terminales.")
        return

    print(f"🗺️  Iniciando mapeo para {len(terminales)} orígenes.")
    
    with sync_playwright() as p:
        # Configuración Anti-Bot AGRESIVA
        browser = p.chromium.launch(
            headless=False,
            args=[
                "--start-maximized", 
                "--disable-blink-features=AutomationControlled",
                "--no-sandbox",
                "--disable-setuid-sandbox"
            ]
        )
        context = browser.new_context(
            viewport=None,
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
        )
        page = context.new_page()
        
        # Inyectar script para ocultar webdriver
        page.add_init_script("""
            Object.defineProperty(navigator, 'webdriver', {
                get: () => undefined
            })
        """)
        
        try:
            print("⏳ Cargando ADO...")
            page.goto("https://www.ado.com.mx/", timeout=90000)
            page.wait_for_load_state("domcontentloaded")
            time.sleep(5) 
            
            # DIAGNÓSTICO DE BLOQUEO
            titulo = page.title()
            print(f"ℹ️ Título de la página: {titulo}")
            
            if "Access Denied" in titulo or "Just a moment" in titulo or "Security" in titulo:
                print(f"⛔ BLOQUEO DETECTADO. El servidor rechazó la conexión.")
                print("⚠️ PAUSA MANUAL: Resuelve el CAPTCHA en el navegador y presiona ENTER aquí en la consola.")
                input("Presiona ENTER cuando veas la página de inicio normal...")

            intentar_cerrar_popups(page)
        except Exception as e:
            print(f"❌ Error carga inicial: {e}")
            return

        for i, terminal_origen in enumerate(terminales):
            nombre = terminal_origen if isinstance(terminal_origen, str) else terminal_origen.get("name", "")
            if not nombre: continue

            print(f"📍 ({i+1}/{len(terminales)}) Origen: {nombre}")
            
            try:
                # 1. ENCONTRAR INPUT (Estrategia Nuclear)
                input_origen = None
                
                # Lista de selectores
                selectores = [
                    "input[placeholder='Origen']",
                    "input[name='origin']",
                    "[role='combobox']",
                    "input[type='text']" # Último recurso: agarra el primer input de texto
                ]

                for sel in selectores:
                    if page.is_visible(sel):
                        # Validación extra: asegurarse que no sea el de búsqueda global o newsletter
                        candidato = page.locator(sel).first
                        box = candidato.bounding_box()
                        if box and box['y'] < 500: # Asumimos que el buscador está arriba
                            input_origen = candidato
                            print(f"   🔧 Input encontrado con selector: {sel}")
                            break
                
                # RECARGA DE EMERGENCIA
                if not input_origen:
                    print("   ⚠️ Input no visible. Recargando página...")
                    page.reload()
                    page.wait_for_load_state("networkidle", timeout=10000)
                    time.sleep(3)
                    intentar_cerrar_popups(page)
                    # Reintento rápido
                    if page.is_visible("input[placeholder='Origen']"):
                        input_origen = page.locator("input[placeholder='Origen']").first
                
                if not input_origen:
                    print(f"   ❌ ERROR FATAL: No encuentro dónde escribir.")
                    # Guardar HTML para debug
                    with open(f"debug_error_{i}.html", "w", encoding="utf-8") as f:
                        f.write(page.content())
                    page.screenshot(path=f"debug_error_{i}.png")
                    print(f"   📸 Guardado debug_error_{i}.png y .html")
                    continue

                # 2. INTERACCIÓN
                input_origen.click(force=True)
                # Triple click selecciona todo el texto usualmente
                input_origen.click(click_count=3)
                page.keyboard.press("Backspace")
                time.sleep(0.5)
                
                # Escribir
                page.keyboard.type(nombre, delay=150)
                time.sleep(2.5) # Esperar sugerencias
                
                # Seleccionar
                page.keyboard.press("Enter")
                time.sleep(1)

                # 3. IR A DESTINO
                try:
                    # Intento click en destino
                    dest = page.locator("input[placeholder='Destino']").first
                    if dest.is_visible():
                        dest.click(force=True)
                    else:
                        page.keyboard.press("Tab")
                except: 
                    page.keyboard.press("Tab")
                
                time.sleep(3.0) 

                # 4. EXTRAER RESULTADOS
                opciones = []
                # Buscar cualquier item de lista visible
                locators_lista = page.locator("li[role='option'], .suggestion-item, ul[role='listbox'] li").all_inner_texts()
                
                count_nuevos = 0
                for txt in locators_lista:
                    limpio = txt.split("\n")[0].strip()
                    if limpio and limpio != nombre and len(limpio) > 2 and "Selecciona" not in limpio:
                        rutas_validas.append({
                            "origin_name": nombre,
                            "destination_name": limpio,
                            "origin_slug": nombre.lower().replace(" ", "-"),
                            "destination_slug": limpio.lower().replace(" ", "-")
                        })
                        count_nuevos += 1

                if count_nuevos > 0:
                    print(f"   ✅ {count_nuevos} destinos encontrados.")
                else:
                    print("   ⚠️ 0 destinos (¿Menú no cargó?).")

                # Limpieza para la siguiente iteración
                # Cada 3 búsquedas, vamos al home para limpiar memoria
                if (i + 1) % 3 == 0:
                    page.goto("https://www.ado.com.mx/", timeout=30000)
                    time.sleep(2)
                else:
                    # Opcion rapida: refrescar
                    page.reload()
                    time.sleep(2)

            except Exception as e:
                print(f"   ❌ Excepción: {e}")
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