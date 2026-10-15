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
