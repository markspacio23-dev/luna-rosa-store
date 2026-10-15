import httpx
import os
import json
from dotenv import load_dotenv

load_dotenv()

def analyze_lead_intent(chat_history: str) -> dict:
    """Procesa conversaciones reales en castellano y jopara/guaraní."""
    api_key = os.getenv("LLM_API_KEY")
    api_url = os.getenv("LLM_API_URL")

    if not api_key or "tu_api_key" in api_key:
        return {"intent": "MANUAL_REVIEW", "risk": "HIGH", "confidence_score": 50, "reason": "Falta API Key Real"}

    # Prompt calibrado para el contexto de entregas Contra Reembolso (COD) en Paraguay
    prompt = f"""
    Actúa como un validador de riesgo logístico para e-commerce en Paraguay.
    Analiza esta conversación de WhatsApp donde se ofrece un producto con pago contra entrega:
    "{chat_history}"
    
    Tu objetivo es detectar si el cliente es real, si entiende que debe pagar al recibir y si la dirección es válida.
    Ojo: El cliente paraguayo suele usar expresiones informales, acrónimos o jopara ("dale", "ya está ya", "enviame nomás", "estoy cerca de...").
    
    Devuelve estrictamente un objeto JSON con este formato exacto:
    {{
        "intent": "HIGH_CONFIRMED" o "LOW_CURIOSITY",
        "risk": "HIGH" o "LOW",
        "confidence_score": un entero de 0 a 100,
        "reason": "Breve explicación de por qué es riesgoso o seguro"
    }}
    """
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": "llama-3.3-70b-specdec", # Modelo de Groq ultra rápido y económico
        "messages": [{"role": "user", "content": prompt}],
        "response_format": {"type": "json_object"},
        "temperature": 0.1
    }
    
    try:
        with httpx.Client() as client:
            res = client.post(api_url, json=payload, headers=headers, timeout=15.0)
            if res.status_code == 200:
                return json.loads(res.json()['choices']['message']['content'])
            else:
                return {"intent": "MANUAL_REVIEW", "risk": "HIGH", "confidence_score": 40, "reason": f"API Error: {res.status_code}"}
    except Exception as e:
        return {"intent": "MANUAL_REVIEW", "risk": "HIGH", "confidence_score": 30, "reason": str(e)}
