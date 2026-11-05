# Errores Frecuentes de FastAPI

## 422 Unprocessable Entity
El body no cumple la validación Pydantic.
```python
# Ver el detalle del error
print(response.json()["detail"])
# Verificar tipos: str vs int, Optional vs required, alias de campos
```

## CORS error en el frontend
```python
# main.py — agregar los orígenes correctos
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "https://tudominio.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# Si el frontend envía credentials (cookies/auth), allow_origins NO puede ser ["*"]
```

## RuntimeError: no running event loop
Estás llamando código async desde contexto síncrono.
```python
# ✅ Usar asyncio.run() en scripts standalone
import asyncio
asyncio.run(mi_funcion_async())

# ✅ En FastAPI siempre async def para endpoints con await
@router.get("/")
async def endpoint():
    result = await db_call()
    return result
```

## ImportError circular
```python
# ❌ Evitar imports circulares entre módulos
# ✅ Usar imports dentro de funciones o TYPE_CHECKING
from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from app.models.user import User
```

## Supabase: postgrest.exceptions.APIError
```python
# Código PGRST116 = no rows found (usar .maybe_single() en lugar de .single())
result = supabase.table("products").select("*").eq("id", id).maybe_single().execute()
if result.data is None:
    raise HTTPException(status_code=404, detail="No encontrado")
```

## Variables de entorno no cargan
```python
# Verificar que .env está en la raíz del proyecto (donde corres uvicorn)
# Verificar que pydantic-settings está instalado
pip install pydantic-settings

# En Settings usar model_config
class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env")
```

## TypeError: Object of type X is not JSON serializable
```python
# Pydantic v2 — usar model_dump() en lugar de dict()
return product.model_dump()

# Para Decimal, datetime, UUID — FastAPI los serializa automáticamente
# si el response_model está bien definido
```

## uvicorn: Address already in use
```bash
# Matar el proceso en el puerto 8000
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:8000 | xargs kill -9

# O usar otro puerto
uvicorn app.main:app --reload --port 8001
```

## Dependency injection no funciona como esperado
```python
# ✅ Depends() se resuelve en cada request — no es un singleton
# Para singletons usar lru_cache en la función de factory
from functools import lru_cache

@lru_cache
def get_settings() -> Settings:
    return Settings()

# En la dependency
def get_service(settings: Settings = Depends(get_settings)):
    return MyService(settings)
```

## Background task no ejecuta
```python
# BackgroundTasks solo funciona DESPUÉS de que el response fue enviado
# Para trabajo muy largo usar una queue (Redis + Celery) o Supabase Edge Functions
@router.post("/process")
async def process(bg: BackgroundTasks):
    bg.add_task(long_task)  # se ejecuta tras enviar la respuesta
    return {"status": "queued"}
```
