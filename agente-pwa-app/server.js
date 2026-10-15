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
