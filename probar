#!/data/data/com.termux/files/usr/bin/bash

echo "=================================================="
echo "    REINICIO TOTAL Y PRUEBA AUTOMÁTICA EN TERMUX "
echo "=================================================="

# 1. Matar absolutamente cualquier proceso Python colgado
echo -e "\n[*] 1. Cerrando procesos Python zombis..."
pkill -9 -f python 2>/dev/null
killall -9 python 2>/dev/null
sleep 1

# 2. Instalar librerías necesarias en Python si faltan
echo -e "\n[*] 2. Verificando dependencias (FastAPI / Uvicorn)..."
pip install fastapi uvicorn requests 2>&1 | tail -n 3

# 3. Arrancar main.py en segundo plano guardando registros
echo -e "\n[*] 3. Iniciando 'python main.py'..."
python main.py > servidor.log 2>&1 &
SERVER_PID=$!
sleep 2

# 4. Validar si el proceso sigue vivo o si crasheó
if ! kill -0 $SERVER_PID 2>/dev/null; then
    echo -e "\n[X] EL SERVIDOR FALLÓ AL ARRANCAR. Detalle del error:"
    echo "--------------------------------------------------"
    cat servidor.log
    echo "--------------------------------------------------"
    exit 1
fi

echo "[✓] Servidor activo (PID: $SERVER_PID)"

# 5. Enviar la petición POST con curl
echo -e "\n[*] 4. Enviando mensaje de prueba..."
curl -s -S -X POST http://127.0.0.1:8080/ \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "0976252985",
    "name": "Administrador",
    "message_text": "Ya esta ya el servidor prendido en el puerto 8080, procedemos a validar la conexion contra reembolso en Central."
  }' \
  -w "\n\n[+] Código HTTP: %{http_code}\n[+] Tiempo: %{time_total}s\n"

# 6. Mostrar qué registró el servidor internamente
echo -e "\n[*] 5. Registro interno del servidor (servidor.log):"
tail -n 8 servidor.log

echo -e "\n=================================================="
echo "Prueba completada."
