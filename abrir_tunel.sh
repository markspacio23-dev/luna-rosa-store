#!/data/data/com.termux/files/usr/bin/bash

echo "=================================================="
echo "      APERTURA DE TÚNEL HTTPS PARA WHATSAPP       "
echo "=================================================="

# 1. Asegurar que main.py esté activo en el puerto 8080
if ! ss -tulpn 2>/dev/null | grep -q 8080; then
    echo "[*] Iniciando main.py en segundo plano..."
    python main.py > servidor.log 2>&1 &
    sleep 2
fi

echo "[✓] Servidor E-commerce Autopilot activo en puerto 8080."

# 2. Instalar herramientas de túnel nativas (libres de Node.js)
echo -e "\n[*] Verificando paquetes de red..."
pkg install -y openssh cloudflared >/dev/null 2>&1

echo -e "\n=================================================="
echo "          INICIANDO TÚNEL PÚBLICO HTTPS           "
echo "=================================================="
echo "Instrucciones:"
echo "1. Espera unos segundos hasta ver el enlace https://"
echo "2. Copia esa URL completa."
echo "3. Pégala en el Webhook de WhatsApp / Meta (ej: https://.../)"
echo "4. Deja esta ventana abierta para que el túnel no se cierre."
echo "--------------------------------------------------"

# Intentar primero con Cloudflared si está disponible
if command -v cloudflared >/dev/null 2>&1; then
    echo "[*] Conectando a través de Cloudflare Tunnel..."
    cloudflared tunnel --url http://127.0.0.1:8080
else
    # Fallback inmediato con túnel SSH seguro (sin instalación extra)
    echo "[*] Conectando a través de túnel SSH seguro..."
    ssh -o StrictHostKeyChecking=no -R 80:127.0.0.1:8080 nokey@localhost.run
fi
