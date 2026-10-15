#!/data/data/com.termux/files/usr/bin/bash
clear
echo "🚀 Forzando conexión directa sin proxies al puerto 8080..."
curl -i --noproxy "*" -X POST http://127.0.0 \
  -H "Content-Type: application/json" \
  -d '{"phone":"0976252985","name":"Administrador","message_text":"Validando conexion contra reembolso en Central."}'
echo -e "\n\n✅ Prueba finalizada con tu número."
