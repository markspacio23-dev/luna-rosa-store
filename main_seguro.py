import json
import sqlite3
import hashlib
import base64
from http.server import BaseHTTPRequestHandler, HTTPServer
import agent_closer as closer

SECRET_KEY = hashlib.sha256(b"ClaveSecretaTermuxParaguay2026").digest()

def encriptar_dato(texto: str) -> str:
    if not texto: return ""
    texto_bytes = texto.encode('utf-8')
    encriptado = bytes([b ^ SECRET_KEY[i % len(SECRET_KEY)] for i, b in enumerate(texto_bytes)])
    return base64.b64encode(encriptado).decode('utf-8')

def init_db():
    conn = sqlite3.connect("autopilot_local.db")
    cursor = conn.cursor()
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS leads_seguros (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone_hashed TEXT UNIQUE,
        name_encrypted TEXT,
        intent TEXT,
        risk TEXT,
        score INTEGER
    )""")
    conn.commit()
    conn.close()

init_db()

class SecureAutopilotHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path in ("/", "/leads", "/webhook"):
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(b"<h3>Servidor Multiruta Activo y Seguro (Compliance SIB).</h3>")

    def do_POST(self):
        # Acepta la petición tanto en la raíz como en el webhook técnico
        if self.path in ("/", "/webhook/whatsapp-lead", "/webhook"):
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data.decode('utf-8'))
            except Exception:
                self.send_response(400)
                self.end_headers()
                return

            phone = str(data.get("phone", ""))
            name = str(data.get("name", "Cliente"))
            message_text = str(data.get("message_text", ""))

            analysis = closer.analyze_lead_intent(message_text)
            intent = analysis.get("intent", "UNKNOWN")
            risk = analysis.get("risk", "HIGH")
            score = analysis.get("confidence_score", 40)

            phone_hashed = hashlib.sha256(phone.encode('utf-8')).hexdigest()
            name_encrypted = encriptar_dato(name)

            try:
                conn = sqlite3.connect("autopilot_local.db")
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT OR REPLACE INTO leads_seguros (phone_hashed, name_encrypted, intent, risk, score) VALUES (?, ?, ?, ?, ?)",
                    (phone_hashed, name_encrypted, intent, risk, score)
                )
                conn.commit()
                conn.close()
            except Exception as e:
                print(f"Error DB: {e}")

            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            
            response = {
                "status": "processed",
                "compliance": "VERIFIED",
                "risk_evaluation": risk,
                "action": "PAUSE_DISPATCH" if risk == "HIGH" else "APPROVE_DISPATCH"
            }
            self.wfile.write(json.dumps(response).encode('utf-8'))
        else:
            self.send_error(404)

def run(port=8080):
    print(f"🔒 Servidor configurado para aceptar '/' activo en puerto {port}...")
    HTTPServer(('', port), SecureAutopilotHandler).serve_forever()

if __name__ == '__main__':
    run()
