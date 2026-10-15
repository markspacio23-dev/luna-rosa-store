#!/data/data/com.termux/files/usr/bin/bash

echo "=========================================="
echo "📱 Configurando Autopilot E-commerce en Termux"
echo "=========================================="

# 1. Actualizar paquetes e instalar dependencias básicas en Termux
echo "🔄 Actualizando repositorios y paquetes de Termux..."
pkg update -y && pkg upgrade -y
pkg install -y python git clang libjpeg-turbo libpng libxml2 libxslt

# 2. Crear directorio del proyecto
PROJECT_NAME="autopilot-ecommerce-py"
echo "📂 Creando carpeta del proyecto: $PROJECT_NAME..."
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME" || exit

# 3. Crear archivos esenciales del sistema multi-agente
echo "📝 Generando código de los agentes y archivos de configuración..."

cat << 'INNER_EOF' > README.md
# 🤖 Autopilot E-commerce Paraguay (Multi-Agent Network - Termux Edition)
Ecosistema multi-agente autónomo para dropshipping y COD en Paraguay.
INNER_EOF

cat << 'INNER_EOF' > requirements.txt
pydantic
httpx
uvicorn
fastapi
python-dotenv
INNER_EOF

cat << 'INNER_EOF' > schema.sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    zappy_id TEXT UNIQUE,
    cost_price DECIMAL(10,2),
    stock INT,
    status TEXT DEFAULT 'pending_review'
);

CREATE TABLE leads (
    id SERIAL PRIMARY KEY,
    phone_number VARCHAR(20) UNIQUE,
    full_name TEXT,
    location_geo TEXT,
    trust_score INT DEFAULT 50,
    status TEXT DEFAULT 'evaluating'
);
INNER_EOF

cat << 'INNER_EOF' > agent_market_analyst.py
from pydantic import BaseModel

class ProductCandidate(BaseModel):
    title: str
    zappy_id: str
    cost_price: float
    stock: int
    margin_percentage: float

def analyze_catalog(catalog_data: list) -> list[ProductCandidate]:
    validated_products = []
    for item in catalog_data:
        cost = item.get("cost_price", 0)
        retail = item.get("retail_price", 0)
        if cost > 0 and ((retail - cost) / cost) >= 0.5 and item.get("stock", 0) > 5:
            validated_products.append(
                ProductCandidate(
                    title=item["title"],
                    zappy_id=item["zappy_id"],
                    cost_price=cost,
                    stock=item["stock"],
                    margin_percentage=((retail - cost) / cost) * 100
                )
            )
    return validated_products
INNER_EOF

cat << 'INNER_EOF' > agent_copywriter.py
def generate_local_offer(product_name: str, base_angle: str) -> str:
    return f"Oferta optimizada para {product_name}: [Gancho persuasivo generado por IA con enfoque local para Paraguay]"
INNER_EOF

cat << 'INNER_EOF' > agent_media_buyer.py
def evaluate_and_scale_ads(campaign_metrics: dict) -> str:
    cpa = campaign_metrics.get("cost_per_acquisition_gs", 0)
    max_allowable_cpa = 25000  # En Guaraníes
    if cpa > max_allowable_cpa:
        return "Acción: Apagar anuncio inmediatamente por superar el CPA máximo permitido."
    return "Acción: Escalar presupuesto un 20% de forma gradual."
INNER_EOF

cat << 'INNER_EOF' > agent_closer.py
def calculate_trust_score(response_speed_seconds: int, has_audio_confirmation: bool, location_provided: bool) -> int:
    score = 50
    if response_speed_seconds < 300: score += 20
    if has_audio_confirmation: score += 20
    if location_provided: score += 10
    else: score -= 40
    return max(0, min(100, score))
INNER_EOF

# 4. Configurar entorno virtual en Python y dependencias
echo "🐍 Configurando entorno virtual de Python en Termux..."
python -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 5. Inicializar Git
echo "git Inicializando repositorio Git..."
git init
git branch -M main
git add .
git commit -m "feat: termux automated deploy for autopilot ecommerce paraguay"

echo "=========================================="
echo "✅ ¡Todo listo en Termux!"
echo "Entrá al directorio con: cd $PROJECT_NAME"
echo "Activá tu entorno con: source venv/bin/activate"
echo "=========================================="
