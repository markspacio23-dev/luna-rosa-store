#!/usr/bin/env python3
"""Script para inspeccionar procesos activos y puertos en Termux."""

import os
import subprocess
import sys


def ejecutar(cmd: str) -> str:
    try:
        res = subprocess.run(
            cmd, shell=True, text=True, capture_output=True, timeout=5
        )
        return res.stdout.strip()
    except Exception as e:
        return f"Error: {e}"


def main() -> None:
    print("=" * 50)
    print("      REVISIÓN DE SERVIDOR EN TERMUX")
    print("=" * 50)

    # 1. Ver qué procesos de Python están corriendo
    print("\n[+] 1. PROCESOS PYTHON ACTIVOS:")
    procesos = ejecutar("pgrep -fl python || ps aux | grep -i python")
    if procesos:
        print(procesos)
    else:
        print("    No se detectaron procesos Python explícitos con pgrep.")

    # 2. Ver archivos Python en la carpeta actual
    print("\n[+] 2. ARCHIVOS PYTHON EN ESTE DIRECTORIO (~):")
    archivos = [f for f in os.listdir(".") if f.endswith(".py")]
    if archivos:
        for arch in archivos:
            print(f"    - {arch}")
    else:
        print("    No hay archivos .py en la carpeta actual.")

    # 3. Ver qué responde exactamente el puerto 8080 con GET
    print("\n[+] 3. RESPUESTA HTTP GET DESDE EL PUERTO 8080:")
    curl_get = ejecutar("curl -s -i http://127.0.0.1:8080/ | head -n 15")
    if curl_get:
        print(curl_get)
    else:
        print("    El puerto 8080 no respondió a la consulta local.")

    print("\n" + "=" * 50)


if __name__ == "__main__":
    main()
