#!/data/data/com.termux/files/usr/bin/bash

echo "=================================================="
echo "    DESCUBRIENDO ENDPOINT Y VALIDANDO CENTRAL     "
echo "=================================================="

# 1. Inspeccionar test_autopilot.sh si existe
if [ -f "test_autopilot.sh" ]; then
    echo "[*] Script original 'test_autopilot.sh' encontrado:"
    sed -i 's|127.0.0.0|127.0.0.1:8080|g' test_autopilot.sh
    sed -i 's|127.0.0.1:8080:8080|127.0.0.1:8080|g' test_autopilot.sh
    echo "--------------------------------------------------"
    cat test_autopilot.sh
    echo "--------------------------------------------------"
fi

# 2. Extraer rutas exactas que acepta do_POST en main.py
echo -e "\n[*] Rutas configuradas en main.py para POST:"
grep -n -E "self\.path" main.py

RUTA=$(grep -oE "self\.path\s*==\s*['\"][^'\"]+['\"]" main.py | head -n 1 | awk -F"['\"]" '{print $2}')

if [ -z "$RUTA" ]; then
    RUTA="/webhook"
fi

echo -e "\n[+] Endpoint objetivo detectado: ${RUTA}"
URL_FINAL="http://127.0.0.1:8080${RUTA}"
echo "[*] Enviando mensaje a: ${URL_FINAL}"

# 3. Enviar petición al endpoint correcto
curl -i -X POST "${URL_FINAL}" \
  -H "Content-Type: application/json; charset=UTF-8" \
  -d '{
    "phone": "0976252985",
    "name": "Administrador",
    "message_text": "Ya esta ya el servidor prendido en el puerto 8080, procedemos a validar la conexion contra reembolso en Central."
  }'

# 4. Verificar si se registró en la base de datos SQLite
echo -e "\n\n[*] Verificando registro en SQLite (autopilot_local.db):"
if [ -f "autopilot_local.db" ]; then
    sqlite3 autopilot_local.db "SELECT id, phone, name, intent, risk, score FROM leads ORDER BY id DESC LIMIT 1;" 2>/dev/null || \
    python3 -c "import sqlite3; conn = sqlite3.connect('autopilot_local.db'); print(conn.execute('SELECT * FROM leads ORDER BY rowid DESC LIMIT 1').fetchall())" 2>/dev/null
else
    echo "    La base de datos aún no ha sido creada o está en otra ruta."
fi

echo -e "\n=================================================="
echo "Validación finalizada."
