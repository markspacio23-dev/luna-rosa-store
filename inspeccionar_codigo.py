#!/usr/bin/env python3
"""Localiza el script del E-commerce Autopilot y extrae el manejador POST."""

import os
import sys

def buscar_archivo_servidor() -> str | None:
    for raiz, _, archivos in os.walk("."):
        for archivo in archivos:
            if archivo.endswith(".py") and archivo not in ("descubrir_y_revisar.py", "inspeccionar_codigo.py"):
                ruta = os.path.join(raiz, archivo)
                try:
                    with open(ruta, "r", encoding="utf-8", errors="ignore") as f:
                        contenido = f.read()
                        if "E-commerce Autopilot" in contenido or "BaseHTTPRequestHandler" in contenido:
                            return ruta
                except Exception:
                    continue
    return None

def main() -> None:
    print("=" * 55)
    print("   LOCALIZANDO CÓDIGO DEL SERVIDOR AUTOPILOT")
    print("=" * 55)
    
    archivo = buscar_archivo_servidor()
    if not archivo:
        print("[!] No se encontró el archivo del servidor en esta carpeta.")
        print("Archivos disponibles:")
        for f in os.listdir("."):
            print("  -", f)
        sys.exit(1)
        
    print(f"[+] Archivo detectado: {archivo}")
    print("-" * 55)
    
    with open(archivo, "r", encoding="utf-8", errors="ignore") as f:
        lineas = f.readlines()

    # Extraer el método do_POST o la parte que maneja peticiones
    en_post = False
    bloque_post = []
    
    for i, linea in enumerate(lineas):
        if "def do_POST" in linea or 'elif self.command == "POST"' in linea:
            en_post = True
        
        if en_post:
            bloque_post.append(f"{i+1:4d}: {linea}")
            # Si encontramos otra función con la misma indentación, terminamos el bloque
            if len(bloque_post) > 1 and linea.strip() and not linea.startswith(" ") and not linea.startswith("\t"):
                break
            if len(bloque_post) > 40: # Límite de seguridad
                break

    if bloque_post:
        print("MÉTODO do_POST DETECTADO:")
        print("".join(bloque_post))
    else:
        print("[!] El archivo NO tiene implementado 'def do_POST'.")
        print("Esa es la razón por la que cierra la conexión al recibir un POST.")

    print("=" * 55)

if __name__ == "__main__":
    main()
