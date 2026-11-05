---
name: supabase-expert
description: |
  Experto en la plataforma Supabase: Postgres, RLS, Auth, Edge Functions, Realtime y Storage.
  Actívala SIEMPRE en estos contextos:
  - RLS: políticas, "mi query retorna vacío", "permission denied", multi-tenant
  - Auth: providers OAuth, magic links, tabla profiles, roles, custom claims
  - Edge Functions: crear, deployar, secrets, webhooks en Deno
  - Realtime: canales, postgres_changes, broadcast, presence
  - Storage: buckets, políticas de archivos, signed URLs, subida de imágenes
  - Supabase CLI: migraciones, supabase db push, entorno local, seed
  - anon key vs service_role key — cuándo usar cada una
  - Cualquier mención de: Supabase, supabase-js, @supabase/ssr, supabase_flutter, PostgREST
  Para el código del CLIENTE detecta el SDK y deriva: Next.js → nextjs-expert
  (supabase-ssr.md), Flutter → flutter-expert (supabase-flutter.md),
  FastAPI → fastapi-expert (database.md). Este skill cubre la PLATAFORMA.
---

# Supabase Expert — Plataforma

Eres un experto en Supabase como plataforma: el diseño de la base de datos,
las políticas RLS, auth, funciones y storage. El código del cliente (JS, Dart,
Python) lo cubren los skills de cada stack — no dupliques sus patrones.

---

## FASE 0 — Reconocimiento obligatorio

1. **¿Hay carpeta `supabase/`?** → proyecto con CLI local: revisar
   `supabase/migrations/`, `supabase/config.toml`, `supabase/functions/`.
   Sin carpeta → proyecto solo-remoto (cambios via dashboard/MCP).
2. **¿Qué SDK usa el cliente?** → `@supabase/ssr` (Next.js),
   `supabase_flutter` (Flutter), `supabase` en requirements (Python).
3. **¿Dónde se usa `service_role`?** → Grep por `service_role` — si aparece
   en código de cliente (Flutter, componentes React), es un hallazgo CRÍTICO.

---

## Modelo mental de claves

| Clave | Dónde vive | Qué puede hacer |
|---|---|---|
| `anon` | Cliente (app, navegador) — es pública | Solo lo que las políticas RLS permitan |
| `service_role` | SOLO servidor (backend, Edge Functions, jobs) | TODO — bypasea RLS |

**Reglas:**
- La `anon key` expuesta NO es una vulnerabilidad — la seguridad es RLS.
- `service_role` en un APK, bundle JS o repo público = incidente de seguridad.
- Nunca usar `service_role` para "arreglar" una query que RLS bloquea — eso
  es un bug de políticas que hay que corregir en la política.

---

## La regla central: RLS en todo

```sql
-- TODA tabla expuesta al cliente:
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
```

- Tabla sin RLS + anon key pública = cualquiera lee/escribe todo.
- **Síntoma clásico:** query retorna `[]` o `null` SIN error → una política
  está negando el acceso. Revisar políticas antes de debuggear el código.
- Patrones completos de políticas → `references/rls-policies.md`.

---

## Supabase CLI — flujo de trabajo

```powershell
supabase init                  # crea supabase/ en el proyecto
supabase start                 # stack local en Docker (Postgres, Auth, Storage)
supabase stop

# Migraciones — la BD se versiona como el código
supabase migration new add_orders_table    # crea archivo SQL vacío
supabase db diff -f add_orders_table       # genera migración desde cambios locales
supabase db reset                          # recrea la BD local con migraciones + seed.sql

# Sincronizar con el proyecto remoto
supabase link --project-ref <ref>
supabase db push               # aplica migraciones pendientes al remoto
```

**Reglas:**
- Cambios de esquema SIEMPRE como migración en `supabase/migrations/` —
  versionadas en git. Nada de cambios manuales solo en el dashboard.
- Como en Flyway: nunca editar una migración ya aplicada; corregir = nueva migración.
- `supabase/seed.sql` para datos de desarrollo, no para datos de producción.

---

## Diseño de esquema — convenciones

```sql
create table public.products (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id),
  name text not null,
  price numeric(12,2) not null check (price > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Índice para el patrón de acceso real (filtro por tenant)
create index idx_products_empresa on public.products (empresa_id);

-- updated_at automático
create trigger set_updated_at before update on public.products
  for each row execute function moddatetime(updated_at);
```

- `uuid` como PK (los ids secuenciales filtran información)
- `timestamptz`, nunca `timestamp`
- snake_case en tablas y columnas
- FKs e índices explícitos en la migración

---

## Cuándo usar qué

| Necesidad | Herramienta |
|---|---|
| Lógica de negocio del producto | Backend propio (Spring/FastAPI) — fuente de verdad |
| Reaccionar a cambios de la BD en la UI | Realtime → `references/realtime-storage.md` |
| Webhook receptor / lógica serverless ligera | Edge Function → `references/edge-functions.md` |
| Validación que NUNCA debe saltarse | Constraint o trigger en Postgres (no solo en el cliente) |
| Automatización entre servicios | n8n + webhooks (no Edge Functions kilométricas) |
| Datos derivados costosos | Vista o función SQL, no calcular en el cliente |

---

## Archivos de referencia

- `references/rls-policies.md` — políticas por patrón: owner, multi-tenant, roles, público
- `references/edge-functions.md` — Deno, secrets, webhooks, CORS, deploy
- `references/realtime-storage.md` — canales realtime, buckets, signed URLs
- `references/auth-patterns.md` — providers, tabla profiles, roles con custom claims
