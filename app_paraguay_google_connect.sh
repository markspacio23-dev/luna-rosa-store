#!/bin/bash
echo -e "\e[1;32m[+] Configurando Entorno Todo en Uno con Google Sheets y Drive...\e[0m"

# 1. Instalar dependencias requeridas en el entorno local
pkg install nodejs git -y
mkdir -p ~/tienda_google_py && cd ~/tienda_google_py

# 2. Inicializar Node.js e instalar Express junto con las librerías oficiales de Google
npm init -y
npm install express @google/googleapis body-parser

# 3. Crear carpetas del Frontend
mkdir -p public

# 4. Crear la interfaz web visual (HTML + JS)
cat << 'HTML_EOF' > public/index.html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Catálogo Sincronizado Google Sheets</title>
    <script src="https://jsdelivr.net"></script>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #fafafa; }
        header { text-align: center; padding: 15px; background: #4285F4; color: white; border-radius: 6px; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 15px; margin-top: 20px; }
        .card { background: white; padding: 15px; border-radius: 6px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); text-align: center; }
        .precio { color: #34A853; font-weight: bold; font-size: 1.2em; margin: 10px 0; }
        .btn { background: #4285F4; color: white; border: none; padding: 10px; width: 100%; border-radius: 4px; font-weight: bold; cursor: pointer; }
    </style>
</head>
<body>

<header>
    <h1>📋 Tienda Sincronizada con Google Drive & Sheets</h1>
</header>

<div class="grid" id="productos-grid"></div>

<script>
    // En un entorno de producción real, este array se poblaría consultando
    // directamente el endpoint de la API con los datos reales de Sheets.
    const productos = [
        { id: 1, nombre: "Remera Básica Negra", precio: 85000 },
        { id: 2, nombre: "Gorra Trucker Urbana", precio: 45000 }
    ];

    const grid = document.getElementById('productos-grid');
    grid.innerHTML = productos.map(p => `
        <div class="card">
            <h3>${p.nombre}</h3>
            <div class="precio">Gs. ${p.precio.toLocaleString('es-PY')}</div>
            <button class="btn" onclick="comprar(${p.id}, '${p.nombre}', ${p.precio})">Comprar en un Clic</button>
        </div>
    `).join('');

    async function comprar(id, nombre, precio) {
        Swal.fire('Procesando...', 'Enviando registro a tu Google Sheet', 'info');
        
        const response = await fetch('/registrar-pedido', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id, nombre, precio, fecha: new Date().toLocaleString() })
        });
        
        if (response.ok) {
            Swal.fire('¡Éxito!', 'Pedido insertado de forma segura en la hoja de cálculo.', 'success');
        } else {
            Swal.fire('Error', 'No se pudo conectar con el servidor de Google', 'error');
        }
    }
</script>
</body>
</html>
HTML_EOF

# 5. Crear el Backend inteligente en Node.js conectado a Google Cloud
cat << 'SERVER_EOF' > server.js
const express = require('express');
const bodyParser = require('body-parser');
const { google } = require('googleapis');
const path = require('path');
const app = express();

app.use(express.static(path.join(__dirname, 'public')));
app.use(bodyParser.json());

// ID de la hoja de Google Sheets (Reemplazar con el tuyo propio)
const SPREADSHEET_ID = 'TU_ID_DE_GOOGLE_SHEETS_AQUI';

// Autenticación con Google Workspace usando las llaves descargadas
const auth = new google.auth.GoogleAuth({
    keyFile: 'credentials.json',
    scopes: [
        'https://googleapis.com',
        'https://googleapis.com'
    ]
});

// Endpoint para guardar registros de compras en caliente en Sheets
app.post('/registrar-pedido', async (req, res) => {
    try {
        const { id, nombre, precio, fecha } = req.body;
        const client = await auth.getClient();
        const googleSheets = google.sheets({ version: 'v4', auth: client });
        
        await googleSheets.spreadsheets.values.append({
            auth,
            spreadsheetId: SPREADSHEET_ID,
            range: 'Sheet1!A:D',
            valueInputOption: 'USER_ENTERED',
            resource: {
                values: [[fecha, id, nombre, `Gs. ${precio.toLocaleString('es-PY')}`]]
            }
        });
        res.sendStatus(200);
    } catch (error) {
        console.error("Error al escribir en Google Sheets:", error);
        res.status(500).send(error);
    }
});

app.listen(8080, () => console.log('\n 🌐 Servidor comercial integrado con Google Drive corriendo en http://localhost:8080'));
SERVER_EOF

echo -e "\e[1;33m⚠️ RECUERDA: Coloca tu archivo 'credentials.json' dentro de la carpeta '~/tienda_google_py' y edita el 'SPREADSHEET_ID' en server.js para finalizar el enlace de datos.\e[0m"
node server.js
