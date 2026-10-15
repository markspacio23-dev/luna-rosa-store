import httpx
import os
from dataclasses import dataclass
from dotenv import load_dotenv

load_dotenv()

@dataclass
class ProductCandidate:
    title: str
    zappy_id: str
    cost_price: float
    retail_price: float
    stock: int
    margin_gs: float

def analyze_and_filter_catalog(api_url_zappy: str) -> list[ProductCandidate]:
    """Scrapea usando dataclasses nativos compatibles con Python 3.14."""
    validated_products = []
    min_margin = float(os.getenv("MIN_MARGIN_GS", 40000))
    min_stock = int(os.getenv("MIN_STOCK", 15))

    try:
        with httpx.Client() as client:
            response = client.get(api_url_zappy, timeout=8.0)
            if response.status_code != 200:
                return []
            catalog_data = response.json().get("products", [])
            
        for item in catalog_data:
            cost = float(item.get("cost_price", 0))
            retail = float(item.get("retail_price", 0))
            stock = int(item.get("stock", 0))
            margin = retail - cost
            
            if margin >= min_margin and stock >= min_stock:
                validated_products.append(
                    ProductCandidate(
                        title=item["title"],
                        zappy_id=str(item["id"]),
                        cost_price=cost,
                        retail_price=retail,
                        stock=stock,
                        margin_gs=margin
                    )
                )
        return validated_products
    except Exception as e:
        print(f"[Error Analista]: {str(e)}")
        return []
