from playwright.sync_api import sync_playwright
import time
import csv
import os
import re
from datetime import datetime, timedelta

def verify_save():
    # Ruta conocida que DEBE funcionar: México TAPO -> Veracruz
    # Slug extraído de terminals.json (verificado visualmente o inferido)
    origen_slug = "ciudad-puebla-pue"
    destino_slug = "ciudad-veracruz-ver"
    fecha_str = (datetime.now() + timedelta(days=1)).strftime("%d/%m/%Y")
    
    base_url = f"https://www.ado.com.mx/viajes/{origen_slug}-a-{destino_slug}/"
    variations = [
        f"?fechaIda={fecha_str}", 
        "", 
    ]
    
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        # Usar mismo UA que el scraper principal
        context = browser.new_context(user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        page = context.new_page()
        
        for url_suffix in variations:
            full_url = base_url + url_suffix
            print(f"🧪 Probando: {full_url}")
            try:
                page.goto(full_url, timeout=20000)
                try:
                    page.wait_for_selector("div[class*='TripCard']", timeout=10000)
                    print("   ✅ ¡ÉXITO! Tarjetas encontradas.")
                    break
                except:
                    print("   ❌ Falló (Timeout/No resultados).")
            except Exception as e:
                print(f"   ❌ Error carga: {e}")
                
        browser.close()

if __name__ == "__main__":
    verify_save()
