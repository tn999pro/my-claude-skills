# Patrones de Autenticación

## §Supabase Auth

```python
# dependencies.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.db import get_supabase

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
):
    token = credentials.credentials
    supabase = get_supabase()
    try:
        user = supabase.auth.get_user(token)
        if not user.user:
            raise HTTPException(status_code=401, detail="Token inválido")
        return user.user
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No autenticado",
            headers={"WWW-Authenticate": "Bearer"},
        )

# Dependency opcional (no falla si no hay token)
async def get_optional_user(
    credentials: HTTPAuthorizationCredentials = Depends(HTTPBearer(auto_error=False)),
):
    if not credentials:
        return None
    return await get_current_user(credentials)
```

### Uso en routers
```python
@router.post("/products")
async def create(
    data: ProductCreate,
    current_user=Depends(get_current_user),  # protegido
):
    ...

@router.get("/catalog/{slug}")
async def get_catalog(
    slug: str,
    user=Depends(get_optional_user),  # público pero con contexto si hay auth
):
    ...
```

---

## §JWT Manual

```python
# auth.py
from jose import JWTError, jwt
from datetime import datetime, timedelta
from app.config import settings

def create_access_token(data: dict, expires_delta: timedelta = timedelta(hours=24)) -> str:
    payload = {**data, "exp": datetime.utcnow() + expires_delta}
    return jwt.encode(payload, settings.secret_key, algorithm="HS256")

def verify_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.secret_key, algorithms=["HS256"])
    except JWTError:
        raise HTTPException(status_code=401, detail="Token inválido o expirado")

# Dependency
async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(HTTPBearer()),
    db: AsyncSession = Depends(get_db),
):
    payload = verify_token(credentials.credentials)
    user = await user_service.get_by_id(db, payload["sub"])
    if not user:
        raise HTTPException(status_code=401, detail="Usuario no encontrado")
    return user
```

---

## §API Key

```python
from fastapi.security import APIKeyHeader

API_KEY_HEADER = APIKeyHeader(name="X-API-Key")

async def verify_api_key(api_key: str = Depends(API_KEY_HEADER)):
    if api_key != settings.api_key:
        raise HTTPException(status_code=403, detail="API key inválida")
    return api_key
```

---

## Roles y permisos

```python
from enum import Enum

class Role(str, Enum):
    ADMIN = "admin"
    VENDOR = "vendor"
    VIEWER = "viewer"

def require_role(*roles: Role):
    async def check(current_user=Depends(get_current_user)):
        if current_user.role not in roles:
            raise HTTPException(status_code=403, detail="Sin permisos")
        return current_user
    return check

# Uso
@router.delete("/{id}")
async def delete(id: str, user=Depends(require_role(Role.ADMIN))):
    ...
```
