#!/data/data/com.termux/files/usr/bin/bash

echo "=================================================="
echo "    AUDITORÍA DE BASE DE DATOS Y TÚNEL PÚBLICO    "
echo "=================================================="

# ---------------------------------------------------------
# FASE 1: AUDITORÍA DE DATOS EN autopilot_local.db
# ---------------------------------------------------------
echo -e "\n[*] 1. Auditando registros locales en SQLite..."

python3 - << 'PYEOF'
import sqlite3
import os

DB_FILE = "autopilot_local.db"

if not os.path.exists(DB_FILE):
    print(f"[!] No se encontró el archivo {DB_FILE}")
else:
    try:
        conn = sqlite3.connect(DB_FILE)
        cursor = conn.cursor()
        
        # Obtener columnas
        cursor.execute("PRAGMA table_info(leads);")
        columnas = [col[1] for col in cursor.fetchall()]
        
        # Obtener último lead
        cursor.execute("SELECT * FROM leads ORDER BY rowid DESC LIMIT 1;")
        fila = cursor.fetchone()
        
        if fila:
            print("[✓] Registro verificado con éxito:")
            print("-" * 45)
            for col, val in zip(columnas, fila):
                print(f"  • {col:12s}: {val}")
            print("-" * 45)
        else:
            print("[*] La tabla 'leads' existe pero no contiene filas.")
        conn.close()
    except Exception as e:
        print(f"[!] Error al consultar SQLite: {e}")
PYEOF

# ---------------------------------------------------------
# FASE 2: VERIFICACIÓN DEL SERVIDOR EN PUERTO 8080
# ---------------------------------------------------------
echo -e "\n[*] 2. Verificando que main.py esté activo en el puerto 8080..."
if ! ss -tulpn 2>/dev/null | grep -q 8080; then
    echo "[!] El servidor no estaba activo. Iniciando en segundo plano..."
    python main.py > servidor.log 2>&1 &
    sleep 2
    echo "[✓] Servidor activo."
else
    echo "[✓] Servidor ya activo en puerto 8080."
fi

# ---------------------------------------------------------
# FASE 3: INSTALACIÓN Y APERTURA DE LOCALTUNNEL
# ---------------------------------------------------------
echo -e "\n[*] 3. Configurando entorno para Localtunnel..."

# Verificar si nodejs está instalado
if ! command -v node >/dev/null 2>&1; then
    echo "[*] Instalando Node.js en Termux..."
    pkg install -y nodejs-lts >/dev/null 2>&1
fi

# Verificar si localtunnel (lt) está instalado globalmente
if ! command -v lt >/dev/null 2>&1; then
    echo "[*] Instalando paquete localtunnel..."
    npm install -g localtunnel >/dev/null 2>&1
fi

# Obtener la IP pública saliente (contraseña requerida por Localtunnel en la web)
IP_TUNEL=$(curl -s https://loca.lt/mytunnelpassword || curl -s https://ifconfig.me)

echo -e "\n=================================================="
echo "           TÚNEL PÚBLICO ACTIVADO                "
echo "=================================================="
echo "-> Puerto local vinculado : 8080"
echo "-> Contraseña del túnel   : $IP_TUNEL"
echo "   (Si el navegador te pide contraseña al entrar, pega esa IP)"
echo "--------------------------------------------------"
echo "Levantando túnel público... Espera el enlace HTTPS:"
echo "--------------------------------------------------"

# Ejecutar el túnel (Mantener en ejecución)
lt --port 8080
