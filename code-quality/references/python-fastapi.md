# Reglas específicas — Python / FastAPI

## 🔴 CRÍTICO

### Credenciales y secrets
```python
# ❌ Hardcodeado en el código
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
SECRET_KEY = "mysecret123"

# ✅ Siempre desde variables de entorno
from pydantic_settings import BaseSettings
class Settings(BaseSettings):
    supabase_key: str
    secret_key: str
    model_config = ConfigDict(env_file=".env")
```

### SQL Injection en queries raw
```python
# ❌ F-string en query
cursor.execute(f"SELECT * FROM users WHERE name = '{name}'")

# ✅ Parámetros parametrizados
cursor.execute("SELECT * FROM users WHERE name = %s", (name,))
```

### Datos sensibles en logs
```python
# ❌
logger.info(f"Login: user={email}, password={password}")

# ✅
logger.info(f"Login exitoso: user={email}")
```

### except genérico vacío
```python
# ❌
try:
    api_call()
except:  # captura TODO incluyendo SystemExit, KeyboardInterrupt
    pass

# ✅
try:
    api_call()
except httpx.HTTPError as e:
    logger.error("API error: %s", e)
    raise HTTPException(status_code=502, detail="Error en servicio externo")
```

---

## 🟡 MEDIO

### N+1 en loops de BD
```python
# ❌ Query por cada producto
products = supabase.table("products").select("*").execute().data
for p in products:
    category = supabase.table("categories").select("*").eq("id", p["category_id"]).execute().data

# ✅ JOIN en una sola query
products = supabase.table("products").select("*, category:categories(name)").execute().data
```

### Funciones largas — separar responsabilidades
```python
# ❌ Función de 80 líneas que hace todo
async def upload_and_process(file: UploadFile, db=Depends()):
    # validar
    # comprimir
    # subir a storage
    # llamar a Gemini
    # guardar en BD
    # enviar notificación

# ✅ Delegar a servicios especializados
async def upload_and_process(file: UploadFile, service: UploadService = Depends()):
    validated = await service.validate(file)
    compressed = await service.compress(validated)
    url = await service.upload_to_storage(compressed)
    analysis = await service.analyze_with_ai(url)
    return await service.save_product(analysis, url)
```

### Sin paginación
```python
# ❌
@router.get("/products")
async def list_products():
    return supabase.table("products").select("*").execute().data

# ✅
@router.get("/products")
async def list_products(skip: int = 0, limit: int = Query(default=20, le=100)):
    return supabase.table("products").select("*").range(skip, skip + limit - 1).execute().data
```

### Background tasks vs async
```python
# ❌ Operación lenta en el request thread
@router.post("/analyze")
async def analyze(file: UploadFile):
    result = await heavy_ai_processing(file)  # bloquea el cliente 30s
    return result

# ✅ BackgroundTasks para trabajo largo
@router.post("/analyze")
async def analyze(file: UploadFile, bg: BackgroundTasks):
    job_id = str(uuid4())
    bg.add_task(heavy_ai_processing, file, job_id)
    return {"job_id": job_id, "status": "processing"}
```

---

## 🟢 BAJO

### Type hints incompletos
```python
# ❌
def process(data, config):
    return data

# ✅
async def process(data: list[dict], config: AppConfig) -> ProcessResult:
    return ProcessResult(items=data)
```

### Magic strings/numbers
```python
# ❌
if product["gender"] == "D":
    ...
await asyncio.sleep(4)

# ✅
class Gender(str, Enum):
    DAMA = "DAMA"
    HOMBRE = "HOMBRE"
    BABY = "BABY"

GEMINI_RATE_LIMIT_DELAY = 4.0  # segundos entre batches (15 RPM)
```

### Tests con pytest
```python
# Estructura mínima
def test_create_product_success(client, mock_supabase):
    # Arrange
    mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [
        {"id": "1", "name": "Nike Air"}
    ]
    # Act
    response = client.post("/api/products/", json={"name": "Nike Air", "price": 150000})
    # Assert
    assert response.status_code == 201
    assert response.json()["name"] == "Nike Air"

def test_create_product_invalid_price(client):
    response = client.post("/api/products/", json={"name": "Test", "price": -100})
    assert response.status_code == 422
```
