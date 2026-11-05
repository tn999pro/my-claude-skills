# Seguridad backend — Spring Boot y FastAPI

## Spring Boot

### Tabla de detección

| Buscar (Grep) | Si aparece | Severidad |
|---|---|---|
| `jwt.secret` con valor literal en `application.properties` commiteado | Secret de firma expuesto | 🔴 |
| `expiration` > 7200000 (2h) sin refresh token | Tokens robados sirven por horas/días | 🟡 |
| `new HashSet<>()` cerca de "blacklist"/"revoked" | Blacklist en memoria: se pierde al reiniciar | 🟡 |
| `allowedOrigins("*")` o `setAllowedOriginPatterns.*\*` | CORS abierto | 🔴 si hay credenciales |
| `@Query` con concatenación `"... + ` | SQL injection | 🔴 |
| `permitAll()` | Verificar que cada ruta pública sea intencional | revisar |
| `log\.(info|debug).*password|token|secret` | Datos sensibles en logs | 🟡 |
| `printStackTrace|e.getMessage()` devuelto al cliente | Fuga de detalles internos | 🟡 |

### Fixes clave

```java
// 🔴 SQL injection en @Query
// ❌ @Query("SELECT u FROM User u WHERE u.name = '" + name + "'")
// ✅ Parámetros nombrados SIEMPRE
@Query("SELECT u FROM User u WHERE u.name = :name")
User findByName(@Param("name") String name);
```

```java
// 🔴 Secret y expiración: por entorno, nunca en el repo
// application.properties (commiteado) → solo placeholders
jwt.secret=${JWT_SECRET}
jwt.expiration=${JWT_EXPIRATION:3600000}
```

```java
// 🟡 Blacklist persistente (no Set en memoria)
@Repository
public interface RevokedTokenRepository extends JpaRepository<RevokedToken, String> {
    boolean existsByJtiAndExpiresAtAfter(String jti, Instant now);
}
// Job @Scheduled que borra los expirados
```

```java
// 🔴 CORS: orígenes explícitos por entorno
config.setAllowedOrigins(List.of(allowedOrigins));   // de properties
config.setAllowCredentials(true);                     // jamás junto a "*"
```

```java
// 🟡 Respuesta de error sin detalles internos (handler global)
@ExceptionHandler(Exception.class)
public ResponseEntity<ErrorResponse> handle(Exception e) {
    log.error("Error inesperado", e);                 // detalle al log interno
    return ResponseEntity.internalServerError()
        .body(new ErrorResponse("Error interno"));    // genérico al cliente
}
```

Checklist extra Spring:
- [ ] `@EnableMethodSecurity` activo y `@PreAuthorize` en todo controller no público
- [ ] BCrypt para contraseñas (nunca MD5/SHA-1/texto plano)
- [ ] `server.error.include-stacktrace=never` en producción
- [ ] Actuator: endpoints sensibles (`/actuator/env`, `/heapdump`) no expuestos

---

## FastAPI

### Tabla de detección

| Buscar (Grep) | Si aparece | Severidad |
|---|---|---|
| `= ['"](sk-|eyJ|AIza)` en `.py` | API key hardcodeada | 🔴 |
| `except:` o `except Exception:` + `pass` en flujos de auth | Fallos de auth silenciados | 🔴 |
| `allow_origins=\["\*"\]` junto a `allow_credentials=True` | CORS inválido/peligroso | 🔴 |
| `f"SELECT|f"INSERT|f"UPDATE` | SQL injection en query raw | 🔴 |
| Router sin `Depends(get_current_user)` (no público) | Endpoint abierto | 🔴 |
| `@router.post` de upload sin validar content-type/tamaño | Upload arbitrario | 🟡 |
| Sin `slowapi`/rate limit en login y endpoints costosos | Fuerza bruta / abuso | 🟡 |

### Fixes clave

```python
# 🔴 Validación de uploads — nunca confiar en el nombre/extensión
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_SIZE = 5 * 1024 * 1024

@router.post("/upload")
async def upload(file: UploadFile, user=Depends(get_current_user)):
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(status_code=422, detail="Tipo de archivo no permitido")
    contents = await file.read()
    if len(contents) > MAX_SIZE:
        raise HTTPException(status_code=413, detail="Archivo muy grande")
    # nombre generado, NUNCA file.filename del cliente
    path = f"uploads/{uuid4()}.{file.content_type.split('/')[1]}"
```

```python
# 🟡 Rate limiting en endpoints sensibles (slowapi)
@router.post("/auth/login")
@limiter.limit("5/minute")          # frena fuerza bruta
async def login(request: Request, data: LoginRequest): ...
```

```python
# 🔴 La validación Pydantic ES la primera defensa — estricta, no laxa
class OrderCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")   # rechaza campos no esperados
    quantity: int = Field(gt=0, le=1000)
    product_id: UUID                            # tipo fuerte, no str libre
```

```python
# 🟡 Errores de servicios externos sin filtrar detalles al cliente
except httpx.HTTPError as e:
    logger.error("Fallo servicio externo: %s", e)          # detalle interno
    raise HTTPException(status_code=502, detail="Servicio no disponible")
```

Checklist extra FastAPI:
- [ ] `Settings` de pydantic-settings — cero `os.environ` sueltos con defaults inseguros
- [ ] `debug=False` y docs (`/docs`, `/redoc`) desactivadas o protegidas en producción
- [ ] Comparación de API keys con `secrets.compare_digest` (no `==`)
- [ ] Webhooks entrantes: validar secret/firma SIEMPRE (ver n8n en platform-security.md)
