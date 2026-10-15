#!/bin/bash
set -e
cd ~/agente-pwa-app

echo "🔧 1/6 Creando estructura de carpetas..."
mkdir -p public

echo "📝 2/6 Verificando API Key de Gemini..."
CURRENT_KEY=$(grep -oP '(?<=GEMINI_API_KEY=).*' .env 2>/dev/null || echo "")

if [[ -z "$CURRENT_KEY" || ! "$CURRENT_KEY" =~ ^AIzaSy ]]; then
  echo "⚠️  La clave actual NO es válida (debe empezar con AIzaSy...)."
  echo "   Obtén una gratis aquí: https://aistudio.google.com/app/apikey"
  echo ""
  read -p "👉 Pega tu API Key de Gemini y presiona Enter: " NEW_KEY
  if [[ ! "$NEW_KEY" =~ ^AIzaSy ]]; then
    echo "❌ Esa clave no parece válida. Abortando."
    exit 1
  fi
  cat << EOF > .env
GEMINI_API_KEY=$NEW_KEY
PORT=3000
EOF
  echo "✅ Guardada en .env"
else
  echo "✅ Ya tienes una clave válida (empieza con: ${CURRENT_KEY:0:8}...)"
fi

echo "📦 3/6 Instalando dependencias..."
npm init -y > /dev/null 2>&1 || true
npm install express dotenv @google/generative-ai > /dev/null 2>&1

echo "🖥️  4/6 Escribiendo server.js..."
cat << 'EOF' > server.js
require('dotenv').config();
const express = require('express');
const path = require('path');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

app.post('/api/chat', async (req, res) => {
  try {
    const { message } = req.body;
    const result = await model.generateContent(message);
    const reply = result.response.text();
    res.json({ reply });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Servidor listo en http://localhost:${PORT}`);
});
EOF

echo "🎨 5/6 Escribiendo public/index.html..."
cat << 'EOF' > public/index.html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mi Agente de IA</title>
  <style>
    * { box-sizing: border-box; }
    body { margin: 0; font-family: system-ui, sans-serif; background: #0f172a; color: #e2e8f0; display: flex; flex-direction: column; height: 100vh; }
    header { background: #1e293b; padding: 16px; text-align: center; font-weight: 600; }
    #chat { flex: 1; padding: 16px; overflow-y: auto; display: flex; flex-direction: column; gap: 10px; }
    .msg { max-width: 80%; padding: 10px 14px; border-radius: 14px; line-height: 1.4; white-space: pre-wrap; }
    .user { align-self: flex-end; background: #2563eb; color: white; }
    .bot { align-self: flex-start; background: #1e293b; }
    .error { align-self: flex-start; background: #7f1d1d; color: #fecaca; font-size: 13px; }
    form { display: flex; padding: 12px; gap: 8px; background: #1e293b; }
    input { flex: 1; padding: 12px; border-radius: 10px; border: none; background: #0f172a; color: white; font-size: 15px; }
    button { padding: 12px 20px; border-radius: 10px; border: none; background: #2563eb; color: white; font-weight: 600; cursor: pointer; }
    button:disabled { opacity: 0.5; }
  </style>
</head>
<body>
  <header>Mi Agente de IA</header>
  <div id="chat"></div>
  <form id="form">
    <input id="input" placeholder="Escribe un mensaje..." autocomplete="off" />
    <button id="send">Enviar</button>
  </form>
  <script>
    const chat = document.getElementById('chat');
    const form = document.getElementById('form');
    const input = document.getElementById('input');
    const send = document.getElementById('send');

    function addMsg(text, sender) {
      const div = document.createElement('div');
      div.className = `msg ${sender}`;
      div.innerText = text;
      chat.appendChild(div);
      chat.scrollTop = chat.scrollHeight;
      return div;
    }

    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const text = input.value.trim();
      if (!text) return;
      addMsg(text, 'user');
      input.value = '';
      send.disabled = true;
      const loading = addMsg('Pensando...', 'bot');
      try {
        const res = await fetch('/api/chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ message: text })
        });
        const data = await res.json();
        loading.remove();
        if (data.error) addMsg('Error: ' + data.error, 'error');
        else addMsg(data.reply, 'bot');
      } catch (err) {
        loading.remove();
        addMsg('Error de conexión: ' + err.message, 'error');
      } finally {
        send.disabled = false;
        input.focus();
      }
    });
  </script>
</body>
</html>
EOF

echo "🚀 6/6 Arrancando servidor..."
echo ""
node server.js
