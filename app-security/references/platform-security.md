# Seguridad de plataforma — Supabase, n8n y Docker

## Supabase

### Detección — el barrido SQL (correr en el SQL editor)

```sql
-- 🔴 Tablas expuestas SIN RLS (el hallazgo más grave y más común)
select schemaname, tablename
from pg_tables
where schemaname = 'public'
  and tablename not in (
    select tablename from pg_tables t
    join pg_class c on c.relname = t.tablename
    where c.relrowsecurity = true
  );

-- Alternativa directa:
select relname as tabla, relrowsecurity as rls_activo
from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity;

-- 🟡 Políticas sospechosamente permisivas (using true para escritura)
select tablename, policyname, cmd, qual
from pg_policies
where schemaname = 'public' and qual = 'true' and cmd != 'SELECT';
```

| Hallazgo | Riesgo | Fix |
|---|---|---|
| Tabla pública sin RLS | Cualquiera con la anon key (que es pública) lee/escribe TODO | `alter table X enable row level security;` + políticas (supabase-expert/rls-policies.md) |
| `service_role` en frontend/app/repo | Bypass total de RLS en manos de cualquiera | Rotar la key en el dashboard + moverla solo a servidor |
| Política `using (true)` para INSERT/UPDATE/DELETE | Escritura anónima | Reescribir con `auth.uid()`/tenant |
| Bucket público con documentos sensibles | URLs adivinables/indexables | Bucket privado + signed URLs |
| `user_metadata` usado para roles | El usuario puede editarlo y autoasignarse admin | Roles en tabla propia o `app_metadata` |

Grep en el código cliente: `service_role` — cero apariciones fuera de
código de servidor es lo único aceptable.

---

## n8n

### Tabla de detección

| Verificar | Riesgo | Fix |
|---|---|---|
| Webhooks de producción sin Header Auth | Cualquiera dispara el workflow (spam, datos falsos, costos) | Header Auth con secret en TODOS los Webhook nodes |
| Instancia sin HTTPS | Credenciales y payloads en claro; Meta no entrega webhooks | Reverse proxy con TLS |
| Editor expuesto a internet sin auth fuerte | Acceso total a credenciales y workflows | `N8N_BASIC_AUTH_*` mínimo; ideal detrás de VPN/allowlist de IP |
| `N8N_ENCRYPTION_KEY` no respaldada | Credenciales irrecuperables tras una migración | Respaldarla en el gestor de contraseñas |
| Ejecuciones guardadas con payloads sensibles sin prune | Datos personales acumulados indefinidamente | `EXECUTIONS_DATA_PRUNE=true` + max age |

### ⚠️ Tokens de bots en workflows exportados (regla específica)

**El riesgo:** al hacer backup/export de workflows a git, las credenciales
del sistema de n8n NO se exportan — pero **todo lo que esté pegado dentro de
un nodo SÍ**. Los casos que más se escapan:

- **Telegram bot token** pegado en la URL de un HTTP Request node
  (`https://api.telegram.org/bot123456:ABC.../sendMessage`) en vez de usar
  el nodo Telegram con credencial.
- **WhatsApp Business**: el access token de Meta en un header `Authorization:
  Bearer EAAG...` escrito a mano en el nodo HTTP, y el `phone_number_id` con
  el token en la URL de Graph API.
- Secrets de webhooks escritos como literal en un IF/Code node en vez de `$env`.

**Detección antes de cada commit de workflows:**
```
# Grep sobre los .json exportados:
\d{6,}:[A-Za-z0-9_-]{30,}      ← Telegram bot token
EAA[A-Za-z0-9]{20,}            ← Meta/WhatsApp access token
Bearer [A-Za-z0-9_-]{20,}      ← cualquier bearer pegado
api\.telegram\.org/bot         ← token incrustado en URL
```

**Fix:**
1. Mover el token a una credencial de n8n (Header Auth / Telegram API) o a
   `$env.VARIABLE` — re-exportar y verificar que el JSON quedó limpio.
2. Si un token ya llegó a git: **rotarlo** (BotFather → `/revoke` para
   Telegram; regenerar el token del system user en Meta Business). Borrar el
   archivo no des-expone nada.
3. Añadir el Grep anterior como checklist previo al commit de `automations/`.

---

## Docker / docker-compose

### Tabla de detección

| Buscar | Riesgo | Severidad |
|---|---|---|
| `environment:` con valores literales de passwords/keys en `docker-compose.yml` commiteado | Credenciales en git | 🔴 |
| `ENV API_KEY=...` o `ARG SECRET` usado en build en el Dockerfile | El secret queda horneado en las capas de la imagen (visible con `docker history`) | 🔴 |
| `ports:` exponiendo BD/servicios internos (`5432:5432`, `6379:6379`) | Postgres/Redis accesibles desde fuera del host | 🔴 en servidor público |
| Contenedor corriendo como root (sin `USER` en Dockerfile, sin `user:` en compose) | Un escape o RCE en el contenedor = root | 🟡 |
| Imagen `latest` sin versión fijada | Builds no reproducibles, cambios sorpresa | 🟢 |

### Fixes

```yaml
# 🔴 Credenciales: SIEMPRE referencias a .env (no commiteado), nunca literales
# ❌ environment:
#      - POSTGRES_PASSWORD=supersecreta123
# ✅
services:
  db:
    image: postgres:16.4
    environment:
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}   # vive en .env, en .gitignore
```

```dockerfile
# 🔴 Secrets en runtime, JAMÁS en build
# ❌ ENV GEMINI_API_KEY=AIza...        ← queda en la imagen para siempre
# ❌ ARG SECRET + RUN echo $SECRET     ← queda en docker history
# ✅ La imagen no conoce secretos; se inyectan al correr:
#    docker run --env-file .env mi-imagen
#    (compose: env_file o environment con ${VAR})
```

```yaml
# 🔴 Puertos: lo interno NO se publica; los servicios se hablan por la red interna
services:
  db:
    # ❌ ports: ["5432:5432"]          ← Postgres expuesto al mundo
    expose: ["5432"]                   # solo red interna de compose
  n8n:
    ports: ["127.0.0.1:5678:5678"]     # si hace falta acceso local: bind a localhost,
                                       # y el reverse proxy con TLS es la única cara pública
```

```dockerfile
# 🟡 No correr como root
FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S app && adduser -S app -G app
USER app
COPY --chown=app:app target/app.jar /app/app.jar
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```
```yaml
# En compose para imágenes de terceros que lo permiten:
services:
  n8n:
    user: "1000:1000"
```

Checklist extra Docker:
- [ ] `.env` en `.gitignore` y `.dockerignore` (que no entre al build context)
- [ ] Versiones de imagen fijadas (`postgres:16.4`, no `latest`)
- [ ] `restart: unless-stopped` en servicios productivos
- [ ] Volúmenes de datos con backup — la seguridad incluye no perder los datos
