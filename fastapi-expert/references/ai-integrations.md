# Integraciones de IA

## §Gemini (Google)

### Setup
```python
# SDK actual: google-genai (google-generativeai está deprecado)
# pip install google-genai
from google import genai
from google.genai import types
from app.config import settings

client = genai.Client(api_key=settings.gemini_api_key)
```

### Análisis de imágenes
```python
async def analyze_image(image_bytes: bytes, prompt: str) -> dict:
    response = await client.aio.models.generate_content(
        model="gemini-2.5-flash",
        contents=[
            types.Part.from_bytes(data=image_bytes, mime_type="image/jpeg"),
            prompt,
        ],
    )
    return {"text": response.text}
```

### Batching para respetar rate limits
```python
import asyncio
from typing import Callable

async def process_batch(
    items: list,
    process_fn: Callable,
    batch_size: int = 5,
    delay_seconds: float = 1.0,
) -> list:
    """Procesa items en lotes respetando rate limits (15 RPM default)."""
    results = []
    for i in range(0, len(items), batch_size):
        batch = items[i:i + batch_size]
        batch_results = await asyncio.gather(
            *[process_fn(item) for item in batch],
            return_exceptions=True,
        )
        results.extend(batch_results)
        if i + batch_size < len(items):
            await asyncio.sleep(delay_seconds)  # respetar RPM
    return results
```

### Retry con backoff exponencial
```python
import asyncio
import random

async def call_with_retry(fn, *args, max_retries: int = 3, **kwargs):
    for attempt in range(max_retries):
        try:
            return await fn(*args, **kwargs)
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            wait = (2 ** attempt) + random.uniform(0, 1)
            await asyncio.sleep(wait)
```

### Prompt estructurado para visión
```python
PRODUCT_ANALYSIS_PROMPT = """
Analiza este zapato y responde SOLO en JSON con este formato exacto:
{
  "brand": "nombre de la marca o Genérica si no se ve",
  "model": "modelo del zapato o null",
  "gender": "HOMBRE|DAMA|BABY|UNISEX",
  "colors": ["color1", "color2"],
  "confidence": 0.0
}

Reglas:
- Analiza SOLO el zapato, ignora el fondo y la caja
- confidence: 0.0-1.0 según certeza de la marca
- Si hay texto visible en el zapato, usarlo para la marca
"""
```

---

## §OpenAI

```python
from openai import AsyncOpenAI
from app.config import settings

client = AsyncOpenAI(api_key=settings.openai_api_key)

async def analyze_with_gpt(image_url: str, prompt: str) -> str:
    response = await client.chat.completions.create(
        model="gpt-4o",
        messages=[{
            "role": "user",
            "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": image_url}},
            ],
        }],
        max_tokens=500,
    )
    return response.choices[0].message.content
```

---

## Rate limiting general

```python
# Con slowapi
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@router.post("/analyze")
@limiter.limit("10/minute")
async def analyze(request: Request, ...):
    ...
```
