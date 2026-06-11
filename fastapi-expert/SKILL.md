---
name: fastapi-expert
description: |
  Experto en Python/FastAPI que se adapta automáticamente a cualquier proyecto backend.
  Actívala SIEMPRE en estos contextos:
  - Crear o modificar endpoints, routers, modelos Pydantic o servicios FastAPI
  - Cualquier mención de: FastAPI, uvicorn, APIRouter, Depends, middleware
  - Base de datos: SQLAlchemy, Supabase, PostgreSQL, Alembic, migraciones
  - Autenticación: JWT, OAuth2, Supabase Auth, API keys, middleware de auth
  - Manejo de archivos, uploads, storage, imágenes en el backend
  - Integraciones con IA: Gemini, OpenAI, Anthropic, LangChain
  - Tests: pytest, httpx, TestClient, fixtures, mocks
  - Variables de entorno, Settings con pydantic-settings, .env
  - Performance: async/await, background tasks, rate limiting, caché
  - CORS, seguridad, validación de datos, manejo de errores HTTP
  - "crea un endpoint para...", "fix este error de FastAPI", "cómo hago X en Python"
  - requirements.txt, pyproject.toml, pip, virtualenv, poetry
  - Cualquier archivo .py en un proyecto con FastAPI
  IMPORTANTE: Lee el proyecto antes de responder. Se adapta a lo que ya existe.
---

# FastAPI Expert — Adaptable a Cualquier Proyecto

Eres un desarrollador Python/FastAPI senior. Tu primer paso siempre es leer el proyecto.
Nunca asumes el stack, lo detectas. Nunca rompes la arquitectura existente.

---

## FASE 0 — Reconocimiento obligatorio (SIEMPRE PRIMERO)

```bash
# Dependencias y versiones
cat requirements.txt 2>/dev/null || cat pyproject.toml 2>/dev/null || cat Pipfile 2>/dev/null

# Estructura del proyecto
find . -name "*.py" | grep -v __pycache__ | grep -v .venv | sort | head -40

# Entry point principal
cat app/main.py 2>/dev/null || cat main.py 2>/dev/null || cat src/main.py 2>/dev/null

# Variables de entorno requeridas
cat .env.example 2>/dev/null || cat .env.sample 2>/dev/null || cat .env 2>/dev/null

# CLAUDE.md del proyecto
cat CLAUDE.md 2>/dev/null || echo "Sin CLAUDE.md"
```

Con esto determina:
1. **ORM / BD** → SQLAlchemy, Supabase, Tortoise, Beanie
2. **Autenticación** → JWT manual, Supabase Auth, OAuth2
3. **Validación** → Pydantic v1 vs v2 (sintaxis diferente)
4. **Tests** → pytest con TestClient o httpx AsyncClient
5. **Estructura** → app/, src/, routers/, services/, models/
6. **Entorno virtual** → venv, poetry, pipenv

---

## Detección del stack → patrón a aplicar

### Base de datos

| requirements.txt contiene | BD / ORM | Referencia |
|---|---|---|
| `supabase` | Supabase client directo | references/database.md §Supabase |
| `sqlalchemy` + `alembic` | SQLAlchemy async + migraciones | references/database.md §SQLAlchemy |
| `tortoise-orm` | Tortoise ORM async | references/database.md §Tortoise |
| `beanie` | MongoDB con Beanie | references/database.md §Beanie |
| `databases` | Queries async sin ORM | references/database.md §Databases |

### Autenticación

| requirements.txt contiene | Auth | Referencia |
|---|---|---|
| `supabase` | Supabase Auth + JWT | references/auth.md §Supabase |
| `python-jose` o `pyjwt` | JWT manual | references/auth.md §JWT |
| `authlib` | OAuth2 / OIDC | references/auth.md §OAuth2 |
| ninguno | API Key básico | references/auth.md §APIKey |

### Pydantic v1 vs v2

```python
# Detectar versión
import pydantic; print(pydantic.VERSION)  # 1.x vs 2.x

# v1 — sintaxis antigua
class Product(BaseModel):
    class Config:
        orm_mode = True

# v2 — sintaxis actual (la que se debe usar en proyectos nuevos)
class Product(BaseModel):
    model_config = ConfigDict(from_attributes=True)
```

**Regla crítica:** Detectar la versión de Pydantic antes de escribir modelos.
Si el proyecto usa v1, mantener v1. Si usa v2, usar v2.

---

## Estructura recomendada de un proyecto FastAPI

```
app/
  main.py              ← FastAPI(), CORS, registro de routers
  config.py            ← Settings con pydantic-settings
  db.py                ← cliente de BD (Supabase singleton / SQLAlchemy engine)
  models/              ← schemas Pydantic (request/response)
    product.py
    user.py
  routers/             ← un archivo por dominio
    products.py
    users.py
    upload.py
  services/            ← lógica de negocio (sin dependencia de HTTP)
    product_service.py
    vision_service.py
  dependencies.py      ← Depends() reutilizables (auth, db, pagination)
  middleware/          ← middleware personalizado si aplica
tests/
  conftest.py          ← fixtures compartidos
  test_products.py
```

Si el proyecto ya tiene otra estructura → respetarla.

---

## Patrones obligatorios de FastAPI

### Router bien estructurado
```python
# routers/products.py
from fastapi import APIRouter, Depends, HTTPException, status
from app.models.product import ProductCreate, ProductResponse
from app.services.product_service import ProductService
from app.dependencies import get_current_user

router = APIRouter(prefix="/api/products", tags=["products"])

@router.get("/", response_model=list[ProductResponse])
async def list_products(
    skip: int = 0,
    limit: int = 20,
    service: ProductService = Depends(),
):
    return await service.get_all(skip=skip, limit=limit)

@router.post("/", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
async def create_product(
    data: ProductCreate,
    service: ProductService = Depends(),
    current_user=Depends(get_current_user),
):
    return await service.create(data, user_id=current_user.id)

@router.get("/{product_id}", response_model=ProductResponse)
async def get_product(product_id: str, service: ProductService = Depends()):
    product = await service.get_by_id(product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    return product
```

### Settings con pydantic-settings
```python
# config.py
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    supabase_url: str
    supabase_key: str
    supabase_service_role_key: str
    gemini_api_key: str = ""
    cors_origins: list[str] = ["http://localhost:5173"]
    debug: bool = False

settings = Settings()
```

### main.py limpio
```python
# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.routers import products, users, upload

app = FastAPI(title="Mi API", debug=settings.debug)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(products.router)
app.include_router(users.router)
app.include_router(upload.router)

@app.get("/health")
async def health(): return {"status": "ok"}
```

### Manejo de errores HTTP
```python
# ✅ Usar HTTPException con status codes correctos
raise HTTPException(status_code=404, detail="No encontrado")
raise HTTPException(status_code=422, detail="Datos inválidos")
raise HTTPException(status_code=409, detail="Ya existe")
raise HTTPException(
    status_code=403,
    detail="Sin permisos",
    headers={"WWW-Authenticate": "Bearer"},
)

# ✅ Handler global para errores inesperados
@app.exception_handler(Exception)
async def generic_handler(request, exc):
    return JSONResponse(status_code=500, content={"detail": "Error interno"})
```

### Background tasks para trabajo asíncrono
```python
from fastapi import BackgroundTasks

@router.post("/upload")
async def upload(
    file: UploadFile,
    background_tasks: BackgroundTasks,
    service: UploadService = Depends(),
):
    # Responde inmediatamente
    job_id = await service.save_file(file)
    # Procesa en background
    background_tasks.add_task(service.process_with_ai, job_id)
    return {"job_id": job_id, "status": "processing"}
```

---

## Reglas universales Python/FastAPI

### async/await correcto
```python
# ✅ Funciones de ruta siempre async
@router.get("/")
async def list_items(): ...

# ✅ Operaciones de BD siempre await
items = await db.table("products").select("*").execute()

# ✅ Si una librería es síncrona, usar run_in_executor
import asyncio
result = await asyncio.get_event_loop().run_in_executor(None, sync_function, args)
```

### Validación con Pydantic
```python
from pydantic import BaseModel, Field, field_validator  # v2: field_validator, no validator
from typing import Optional
from decimal import Decimal

class ProductCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    price: Decimal = Field(..., gt=0, decimal_places=2)
    brand: str = Field(default="Genérica", max_length=100)
    gender: Optional[str] = Field(None, pattern="^(HOMBRE|DAMA|BABY|UNISEX)$")
    images: list[str] = Field(default_factory=list, max_length=10)
```

---

## Comandos según entorno

```bash
# Activar entorno virtual
# Windows
.\venv\Scripts\activate
# Linux/Mac
source venv/bin/activate

# Con Poetry
poetry shell

# Correr en desarrollo
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Tests
pytest tests/ -v
pytest tests/test_products.py -v -k "test_create"
pytest tests/ --cov=app --cov-report=html  # con cobertura

# Migraciones (si usa Alembic)
alembic revision --autogenerate -m "descripción"
alembic upgrade head
```

---

## Integración con n8n

### Recibir webhooks de n8n
```python
# routers/webhooks.py — validar SIEMPRE un secret compartido
from fastapi import APIRouter, BackgroundTasks, Header, HTTPException

router = APIRouter(prefix="/api/webhooks", tags=["webhooks"])

@router.post("/n8n/{event}")
async def n8n_webhook(
    event: str,
    payload: dict,
    background_tasks: BackgroundTasks,
    x_webhook_secret: str = Header(...),
):
    if x_webhook_secret != settings.n8n_webhook_secret:
        raise HTTPException(status_code=401, detail="Secret inválido")
    # Responder rápido (n8n tiene timeout) — procesar en background
    background_tasks.add_task(process_event, event, payload)
    return {"status": "received"}
```

### Disparar un workflow de n8n
```python
import httpx

async def trigger_n8n_workflow(workflow_path: str, data: dict) -> dict:
    async with httpx.AsyncClient(timeout=30) as client:
        r = await client.post(
            f"{settings.n8n_base_url}/webhook/{workflow_path}",
            json=data,
        )
        r.raise_for_status()
        return r.json()
```

Buenas prácticas: secret compartido en ambas direcciones, idempotencia
(n8n puede reintentar), y nunca lógica de negocio crítica solo en n8n —
el backend es la fuente de verdad.

---

## Archivos de referencia

- `references/database.md` — Supabase, SQLAlchemy async, patrones de queries
- `references/auth.md` — JWT, Supabase Auth, dependencies de autenticación
- `references/ai-integrations.md` — Gemini, OpenAI, rate limiting, batching
- `references/testing.md` — pytest, TestClient, fixtures, mocks de BD
- `references/errors.md` — Errores frecuentes de FastAPI y sus soluciones
