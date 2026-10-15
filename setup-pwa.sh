#!/usr/bin/env bash
set -e

PROJECT_DIR="$HOME/agente-pwa-app"

echo "🚀 Iniciando configuración de la App PWA de Agente de IA..."

# 1. Crear directorio del proyecto
mkdir -p "$PROJECT_DIR/public"
cd "$PROJECT_DIR"

# 2. Inicializar package.json
cat << 'EON' > package.json
{
  "name": "agente-pwa-app",
  "version": "1.0.0",
  "description": "App PWA moderna para Agente de IA",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "@google/genai": "^2.24.0",
    "dotenv": "^18.0.3",
    "express": "^5.2.1"
  }
}
EON

# 3. Instalar dependencias
echo "📦 Instalando paquetes npm..."
npm install

# 4. Crear archivo .env si no existe
if [ ! -f .env ]; then
    cat << 'EON' > .env
GEMINI_API_KEY=YOUR_GEMINI_API_KEY
PORT=3000
EON
    echo "⚠️ Archivo .env creado. Recuerda asignar tu GEMINI_API_KEY real."
fi

# 5. Crear Servidor Express Backend
echo "⚙️ Configurando server.js..."
cat << 'EON' > server.js
require('dotenv').config();
const express = require('express');
const path = require('path');
const { GoogleGenAI } = require('@google/genai');

const app = express();
const PORT = process.env.PORT || 3000;

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

app.post('/api/chat', async (req, res) => {
    try {
        const { message } = req.body;
        if (!message) return res.status(400).json({ error: 'El mensaje es requerido.' });

        const response = await ai.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: message,
        });

        res.json({ reply: response.text });
    } catch (error) {
        console.error('Error en el servidor:', error.message);
        res.status(500).json({ error: error.message || 'Error procesando la consulta.' });
    }
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`\n✅ Servidor PWA corriendo activamente en http://localhost:${PORT}`);
});
EON

# 6. Crear Manifiesto PWA
echo "📱 Configurando manifest.json y Service Worker..."
cat << 'EON' > public/manifest.json
{
  "short_name": "AgenteIA",
  "name": "Agente de IA Autónomo",
  "icons": [
    {
      "src": "https://via.placeholder.com/192.png?text=IA",
      "type": "image/png",
      "sizes": "192x192"
    },
    {
      "src": "https://via.placeholder.com/512.png?text=IA",
      "type": "image/png",
      "sizes": "512x512"
    }
  ],
  "start_url": "/",
  "background_color": "#0f172a",
  "theme_color": "#0f172a",
  "display": "standalone",
  "orientation": "portrait"
}
EON

# 7. Crear Service Worker
cat << 'EON' > public/sw.js
const CACHE_NAME = 'agente-pwa-v2';
const ASSETS = ['/', '/index.html', '/manifest.json'];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS))
  );
});

self.addEventListener('fetch', (e) => {
  e.respondWith(
    caches.match(e.request).then((res) => res || fetch(e.request))
  );
});
EON

# 8. Crear Interfaz HTML5/CSS3 Moderna (Layout Ajustado con 100dvh)
echo "🎨 Generando interfaz pública moderna..."
cat << 'EON' > public/index.html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <link rel="manifest" href="/manifest.json">
  <meta name="theme-color" content="#0f172a">
  <title>Agente IA Móvil</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: system-ui, -apple-system, sans-serif; }
    html, body { height: 100%; height: 100dvh; width: 100%; overflow: hidden; background-color: #0f172a; color: #f8fafc; }
    body { display: flex; flex-direction: column; }
    
    header {
      background: #1e293b;
      padding: 0.85rem 1rem;
      text-align: center;
      font-weight: 700;
      font-size: 1.1rem;
      border-bottom: 1px solid #334155;
      flex-shrink: 0;
      box-shadow: 0 2px 4px rgba(0,0,0,0.2);
    }

    #chat {
      flex: 1;
      overflow-y: auto;
      padding: 1rem;
      display: flex;
      flex-direction: column;
      gap: 0.75rem;
      scroll-behavior: smooth;
    }

    .msg {
      max-width: 85%;
      padding: 0.75rem 1rem;
      border-radius: 16px;
      font-size: 0.95rem;
      line-height: 1.45;
      word-break: break-word;
      box-shadow: 0 1px 2px rgba(0,0,0,0.15);
    }

    .user {
      background: #2563eb;
      align-self: flex-end;
      color: #ffffff;
      border-bottom-right-radius: 4px;
    }

    .agent {
      background: #334155;
      align-self: flex-start;
      color: #f8fafc;
      border-bottom-left-radius: 4px;
    }

    footer {
      padding: 0.75rem 1rem;
      background: #1e293b;
      display: flex;
      gap: 0.5rem;
      border-top: 1px solid #334155;
      flex-shrink: 0;
    }

    input {
      flex: 1;
      padding: 0.75rem 1rem;
      border-radius: 12px;
      border: 1px solid #475569;
      background: #0f172a;
      color: #ffffff;
      outline: none;
      font-size: 1rem;
      transition: border-color 0.2s;
    }

    input:focus { border-color: #2563eb; }

    button {
      padding: 0.75rem 1.25rem;
      background: #2563eb;
      color: #ffffff;
      border: none;
      border-radius: 12px;
      font-weight: 600;
      font-size: 0.95rem;
      cursor: pointer;
      transition: background 0.2s;
    }

    button:active { background: #1d4ed8; }
  </style>
</head>
<body>
  <header>✨ Mi Agente de IA</header>
  <div id="chat"></div>
  <footer>
    <input type="text" id="userInput" placeholder="Escribe un mensaje..." autocomplete="off">
    <button onclick="sendMessage()">Enviar</button>
  </footer>

  <script>
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/sw.js');
    }

    const inputEl = document.getElementById('userInput');
    inputEl.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') sendMessage();
    });

    async function sendMessage() {
      const text = inputEl.value.trim();
      if (!text) return;

      appendMsg(text, 'user');
      inputEl.value = '';

      try {
        const res = await fetch('/api/chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ message: text })
        });
        const data = await res.json();
        appendMsg(data.reply || data.error, 'agent');
      } catch (e) {
        appendMsg('Error de conexión con el agente.', 'agent');
      }
    }

    function appendMsg(text, sender) {
      const chat = document.getElementById('chat');
      const div = document.createElement('div');
      div.className = `msg ${sender}`;
      div.innerText = text;
      chat.appendChild(div);
      chat.scrollTop = chat.scrollHeight;
    }
  </script>
</body>
</html>
EON

echo "✨ Proyecto configurado exitosamente en $PROJECT_DIR"
echo "Lanzando servidor..."
node server.js
