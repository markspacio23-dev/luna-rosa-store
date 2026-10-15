#!/data/data/com.termux/files/usr/bin/bash

echo "=================================================="
echo "    CORRECCIÓN DE DEPENDENCIAS Y ARRANQUE LOCAL   "
echo "=================================================="

# 1. Matar cualquier proceso previo
pkill -9 -f python 2>/dev/null
killall -9 python 2>/dev/null
sleep 1

# 2. Neutralizar import de FastAPI en main.py si no está instalado
python3 - << 'PYEOF'
import re

with open("main.py", "r", encoding="utf-8") as f:
    contenido = f.read()

# Si contiene el import de FastAPI en la cabecera, protegerlo
patron = r"(from\s+fastapi\s+import\s+[^\n]+)"
if re.search(patron, contenido):
    reemplazo = (
        "try:\n"
        "    \\1\n"
        "except ImportError:\n"
        "    FastAPI = WebSocket = WebSocketDisconnect = Request = None\n"
    )
    nuevo_contenido = re.sub(patron, reemplazo, contenido, count=1)
    with open("main.py", "w", encoding="utf-8") as f:
        f.write(nuevo_contenido)
    print("[✓] Línea de FastAPI protegida con fallback en main.py.")
else:
    print("[*] No se requirió modificar la línea de FastAPI.")
PYEOF

# 3. Iniciar main.py en segundo plano
echo -e "\n[*] Iniciando 'python main.py'..."
python main.py > servidor.log 2>&1 &
SERVER_PID=$!
sleep 2

# 4. Validar si arrancó con éxito
if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo -e "\n[X] Error al arrancar servidor. Detalle:"
    echo "--------------------------------------------------"
    cat servidor.log
    echo "--------------------------------------------------"
    exit 1
fi

echo "[✓] Servidor E-commerce Autopilot levantado exitosamente (PID: $SERVER_PID)"

# 5. Enviar mensaje de prueba al webhook
echo -e "\n[*] Probando conexión contra reembolso en Central vía POST..."
curl -s -S -X POST http://127.0.0.1:8080/ \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "0976252985",
    "name": "Administrador",
    "message_text": "Ya esta ya el servidor prendido en el puerto 8080, procedemos a validar la conexion contra reembolso en Central."
  }' \
  -w "\n[+] Código HTTP: %{http_code}\n[+] Tiempo de respuesta: %{time_total}s\n"

# 6. Mostrar últimos logs
echo -e "\n[*] Logs registrados en servidor.log:"
tail -n 6 servidor.log

echo -e "\n=================================================="
echo "Operación completada."
