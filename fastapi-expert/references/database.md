# Patrones de Base de Datos

## §Supabase

### Cliente singleton
```python
# db.py
from supabase import create_client, Client
from app.config import settings
from functools import lru_cache

@lru_cache
def get_supabase() -> Client:
    return create_client(settings.supabase_url, settings.supabase_key)

@lru_cache
def get_supabase_admin() -> Client:
    # service_role_key: bypasa RLS — usar solo en operaciones admin
    return create_client(settings.supabase_url, settings.supabase_service_role_key)
```

### Queries básicas
```python
supabase = get_supabase()

# SELECT con filtros
result = supabase.table("products") \
    .select("*") \
    .eq("catalog_id", catalog_id) \
    .eq("is_sold_out", False) \
    .order("created_at", desc=True) \
    .range(offset, offset + limit - 1) \
    .execute()
items = result.data

# SELECT con join
result = supabase.table("products") \
    .select("*, catalog:catalogs(slug, name)") \
    .eq("id", product_id) \
    .single() \
    .execute()

# INSERT
result = supabase.table("products") \
    .insert({"name": "Nike Air", "price": 150000}) \
    .execute()
new_product = result.data[0]

# UPDATE
result = supabase.table("products") \
    .update({"is_sold_out": True}) \
    .eq("id", product_id) \
    .execute()

# DELETE (soft delete — preferir update a is_sold_out)
supabase.table("products").delete().eq("id", product_id).execute()

# UPSERT
supabase.table("products") \
    .upsert({"id": product_id, "name": "Updated"}) \
    .execute()
```

### Storage — subir archivos
```python
async def upload_to_storage(bucket: str, path: str, file_bytes: bytes, content_type: str) -> str:
    supabase = get_supabase_admin()  # admin para bypasear RLS en storage
    supabase.storage.from_(bucket).upload(
        path=path,
        file=file_bytes,
        file_options={"content-type": content_type, "upsert": "true"},
    )
    # URL pública
    return supabase.storage.from_(bucket).get_public_url(path)
```

### Manejo de errores Supabase
```python
from postgrest.exceptions import APIError

try:
    result = supabase.table("products").select("*").execute()
except APIError as e:
    if e.code == "PGRST116":  # no rows found
        return None
    raise HTTPException(status_code=500, detail=f"DB error: {e.message}")
```

### RLS — cuándo usar service_role_key
- `anon_key` → operaciones públicas (leer catálogo sin auth)
- `service_role_key` → operaciones admin, bypass de RLS, storage uploads, inserts del servidor
- **Nunca exponer `service_role_key` en el frontend**

---

## §SQLAlchemy async

### Setup
```python
# db.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from app.config import settings

engine = create_async_engine(settings.database_url, echo=settings.debug)
SessionLocal = async_sessionmaker(engine, expire_on_commit=False)

class Base(DeclarativeBase): pass

# Dependency para FastAPI
async def get_db():
    async with SessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

### Modelo
```python
from sqlalchemy import String, Numeric, Boolean, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime

class Product(Base):
    __tablename__ = "products"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    price: Mapped[float] = mapped_column(Numeric(10, 2))
    is_sold_out: Mapped[bool] = mapped_column(Boolean, default=False)
    catalog_id: Mapped[str] = mapped_column(ForeignKey("catalogs.id"))
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)
```

### Queries async
```python
from sqlalchemy import select, update, delete
from sqlalchemy.ext.asyncio import AsyncSession

async def get_products(db: AsyncSession, catalog_id: str) -> list[Product]:
    result = await db.execute(
        select(Product)
        .where(Product.catalog_id == catalog_id, Product.is_sold_out == False)
        .order_by(Product.created_at.desc())
    )
    return result.scalars().all()

async def update_product(db: AsyncSession, product_id: str, data: dict) -> Product:
    await db.execute(update(Product).where(Product.id == product_id).values(**data))
    await db.commit()
    return await db.get(Product, product_id)
```

### Alembic — migraciones
```bash
alembic init alembic
# Editar alembic.ini y env.py con la URL de BD

alembic revision --autogenerate -m "add products table"
alembic upgrade head
alembic downgrade -1   # revertir última migración
alembic history        # ver historial
```
