import json
import sqlite3
from http.server import BaseHTTPRequestHandler, HTTPServer
import agent_closer as closer

def init_db():
    conn = sqlite3.connect("autopilot_local.db")
    cursor = conn.cursor()
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS leads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone TEXT UNIQUE,
        name TEXT,
        intent TEXT,
        risk TEXT,
        score INTEGER,
        chat_text TEXT
    )""")
    conn.commit()
    conn.close()

init_db()

class AutopilotHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        """Sirve la interfaz web visual (Chatbook)."""
        if self.path == "/":
            self.send_response(200)
            self.send_header("Content-type", "text/html; charset=utf-8")
            self.end_headers()
            try:
                with open("templates/index.html", "r", encoding="utf-8") as f:
                    self.wfile.write(f.read().encode("utf-8"))
            except FileNotFoundError:
                self.wfile.write(b"<h3>Error: Falta el archivo templates/index.html</h3>")
        else:
            self.send_error(404, "Ruta no encontrada")

    def do_POST(self):
        """Recibe y procesa los Webhooks reales de WhatsApp."""
        if self.path == "/webhook/whatsapp-lead":
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            
            try:
                data = json.loads(post_data.decode('utf-8'))
            except Exception:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'{"status": "error", "message": "JSON invalido"}')
                return

            phone = str(data.get("phone", "Desconocido"))
            name = str(data.get("name", "Cliente"))
            message_text = str(data.get("message_text", ""))

            # Análisis con tu red de agentes
            analysis = closer.analyze_lead_intent(message_text)
            intent = analysis.get("intent", "UNKNOWN")
            risk = analysis.get("risk", "HIGH")
            score = analysis.get("confidence_score", 40)

            # Persistencia en SQLite local
            try:
                conn = sqlite3.connect("autopilot_local.db")
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT OR REPLACE INTO leads (phone, name, intent, risk, score, chat_text) VALUES (?, ?, ?, ?, ?, ?)",
                    (phone, name, intent, risk, score, message_text)
                )
                conn.commit()
                conn.close()
            except Exception as e:
                print(f"Error DB: {e}")

            # Respuesta al Webhook de WhatsApp
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            
            response = {
                "status": "processed",
                "risk_evaluation": risk,
                "score": score,
                "action": "PAUSE_DISPATCH" if risk == "HIGH" else "APPROVE_DISPATCH"
            }
            self.wfile.write(json.dumps(response).encode('utf-8'))
        else:
            self.send_error(404)

def run(port=8080):
    server_address = ('', port)
    httpd = HTTPServer(server_address, AutopilotHandler)
    print(f"🚀 Autopilot E-commerce corriendo en entorno real en el puerto {port}...")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServidor apagado de forma segura.")

if __name__ == '__main__':
    run()
