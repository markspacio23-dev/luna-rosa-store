#!/data/data/com.termux/files/usr/bin/bash

echo "=================================================="
echo "    INSTALANDO DEPENDENCIAS Y PREPARANDO SERVIDOR "
echo "=================================================="

# 1. Instalar dependencias necesarias en Python
echo -e "\n[*] Instalando/verificando FastAPI y Uvicorn..."
pip install fastapi uvicorn requests 2>&1 | tail -n 5

# 2. Matar forzosamente cualquier proceso colgado en el puerto 8080
echo -e "\n[*] Cerrando procesos zombis en el puerto 8080..."
PID_VIEJO=$(lsof -ti :8080 2>/dev/null)
if [ -n "$PID_VIEJO" ]; then
    kill -9 $PID_VIEJO 2>/dev/null
    echo "[+] Proceso $PID_VIEJO terminado."
else
    # Intento con pkill si lsof no tiene el binario
    pkill -9 -f "python.*8080" 2>/dev/null
fi
sleep 1

# 3. Verificar primeras líneas de main.py
echo -e "\n[*] Encabezado de main.py:"
head -n 12 main.py

echo -e "\n=================================================="
echo "[+] Todo listo. Arrancando main.py en 3 segundos..."
echo "    (Para detener el servidor en cualquier momento usa CTRL + C)"
echo "=================================================="
sleep 2

python main.py
