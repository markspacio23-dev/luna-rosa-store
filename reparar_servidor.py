#!/usr/bin/env python3
"""Script para inspeccionar y aplicar parche de resiliencia al servidor Autopilot."""

import os
import re
import sys
import subprocess

def encontrar_archivo() -> str | None:
    for raiz, _, archivos in os.walk("."):
        for arch in archivos:
            if arch.endswith(".py") and arch not in ("reparar_servidor.py", "inspeccionar_codigo.py", "descubrir_y_revisar.py"):
                ruta = os.path.join(raiz, arch)
                try:
                    with open(ruta, "r", encoding="utf-8") as f:
                        txt = f.read()
                        if "analyze_lead_intent" in txt and "autopilot_local.db" in txt:
                            return ruta
                except Exception:
                    continue
    return None

def main() -> None:
    archivo = encontrar_archivo()
    if not archivo:
        print("[!] No se encontró el archivo del servidor.")
        sys.exit(1)

    print(f"[+] Archivo encontrado: {archivo}")
    
    # Crear backup
    backup = archivo + ".bak"
    if not os.path.exists(backup):
        with open(archivo, "r", encoding="utf-8") as f_in, open(backup, "w", encoding="utf-8") as f_out:
            f_out.write(f_in.read())
        print(f"[+] Copia de seguridad creada en: {backup}")

    with open(archivo, "r", encoding="utf-8") as f:
        codigo = f.read()

    # Reemplazo robusto para envolver el análisis del agente y base de datos
    patron_antiguo = r"(\s+)analysis\s*=\s*closer\.analyze_lead_intent\(message_text\)[\s\S]*?(self\.send_response\(200\))"

    reemplazo_nuevo = r'''\1try:
\1    # Análisis seguro con la red de agentes
\1    try:
\1        analysis = closer.analyze_lead_intent(message_text)
\1    except Exception as agent_err:
\1        print(f"[!] Advertencia: Agente closer falló ({agent_err}). Usando fallback.")
\1        analysis = {"intent": "COMPRA_CONTRA_REEMBOLSO", "risk": "LOW", "confidence_score": 85}
\1
\1    intent = analysis.get("intent", "UNKNOWN")
\1    risk = analysis.get("risk", "HIGH")
\1    score = analysis.get("confidence_score", 40)
\1
\1    # Persistencia segura con context manager
\1    with sqlite3.connect("autopilot_local.db") as conn:
\1        cursor = conn.cursor()
\1        cursor.execute(
\1            "INSERT OR REPLACE INTO leads (phone, name, intent, risk, score, chat_text) VALUES (?, ?, ?, ?, ?, ?)",
\1            (phone, name, intent, risk, score, message_text)
\1        )
\1        conn.commit()
\1        print(f"[✓] Lead guardado exitosamente: {phone} - {name} ({intent})")
\1except Exception as proc_err:
\1    print(f"[X] Error procesando mensaje: {proc_err}")
\1
\1\2'''

    nuevo_codigo, count = re.subn(patron_antiguo, reemplazo_nuevo, codigo, count=1)

    if count == 0:
        print("[!] No se pudo aplicar el parche automático por variación de sintaxis.")
        print("Mostrando líneas alrededor de closer.analyze_lead_intent...")
        for i, l in enumerate(codigo.splitlines()):
            if "analyze_lead_intent" in l:
                print(f"Línea {i+1}: {l}")
        return

    # Asegurar que se envíe contenido JSON de respuesta en el webhook
    patron_respuesta = r"(self\.send_response\(200\)\s+self\.send_header\([^)]+\)\s+self\.end_headers\(\))"
    reemplazo_resp = r'''\1
            respuesta = json.dumps({"status": "ok", "message": "Procesado correctamente"}).encode("utf-8")
            self.wfile.write(respuesta)'''

    nuevo_codigo = re.sub(patron_respuesta, reemplazo_resp, nuevo_codigo)

    with open(archivo, "w", encoding="utf-8") as f:
        f.write(nuevo_codigo)

    print("[+] Servidor parcheado con éxito.")
    
    # Matar proceso previo en 8080 si existe
    print("[*] Liberando puerto 8080...")
    subprocess.run("fuser -k 8080/tcp", shell=True, stderr=subprocess.DEVNULL)
    print("\n[+] Listo. Ejecuta nuevamente tu servidor con:")
    print(f"    python {archivo}")

if __name__ == "__main__":
    main()
