#!/data/data/com.termux/files/usr/bin/bash

echo "=================================================="
echo "    CORRIGIENDO SCRIPT DE PRUEBA Y ENVIANDO      "
echo "=================================================="

# 1. Buscar archivos que contengan el error 127.0.0.0 o el texto de prueba
echo "[*] 1. Buscando el script que tiene el error de tipeo..."
ARCHIVOS_ERRONEOS=$(grep -rl "127.0.0.0" . --exclude="*.log" --exclude="corregir_y_probar.sh" 2>/dev/null)

if [ -n "$ARCHIVOS_ERRONEOS" ]; then
    for arch in $ARCHIVOS_ERRONEOS; do
        echo "[+] Corrigiendo URL en: $arch"
        sed -i 's|127.0.0.0:8080|127.0.0.1:8080|g' "$arch"
        sed -i 's|127.0.0.0/|127.0.0.1:8080/|g' "$arch"
        sed -i 's|127.0.0.0|127.0.0.1:8080|g' "$arch"
    done
fi

# Buscar también por el mensaje de texto del script
SCRIPT_TEST=$(grep -rl "Forzando conexión directa" . --exclude="corregir_y_probar.sh" 2>/dev/null)
if [ -n "$SCRIPT_TEST" ]; then
    echo "[+] Script de prueba detectado: $SCRIPT_TEST"
    # Asegurar corrección de cualquier 127.0.0.0 dentro de este archivo
    sed -i 's|127.0.0.0|127.0.0.1:8080|g' "$SCRIPT_TEST"
    sed -i 's|127.0.0.1:8080:8080|127.0.0.1:8080|g' "$SCRIPT_TEST"
fi

# 2. Asegurarnos de que main.py esté escuchando en el 8080
echo -e "\n[*] 2. Verificando estado del servidor en el puerto 8080..."
if ! ss -tulpn 2>/dev/null | grep -q 8080; then
    echo "[!] El servidor no estaba activo. Iniciando 'python main.py'..."
    python main.py > servidor.log 2>&1 &
    sleep 2
else
    echo "[✓] El servidor ya está activo en el puerto 8080."
fi

# 3. Enviar la petición directamente con la URL bien formada
echo -e "\n[*] 3. Ejecutando la petición con los parámetros correctos:"
echo "    Destino: http://127.0.0.1:8080/"

curl -i -X POST http://127.0.0.1:8080/ \
  -H "Content-Type: application/json; charset=UTF-8" \
  -d '{
    "phone": "0976252985",
    "name": "Administrador",
    "message_text": "Ya esta ya el servidor prendido en el puerto 8080, procedemos a validar la conexion contra reembolso en Central."
  }'

echo -e "\n\n=================================================="
echo "Proceso finalizado con éxito."
