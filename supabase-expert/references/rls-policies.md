# RLS — Políticas por patrón

## Anatomía de una política

```sql
create policy "nombre descriptivo"
on public.tabla
for select | insert | update | delete | all
to authenticated | anon
using (condición)        -- filas visibles/afectables (select/update/delete)
with check (condición);  -- filas que se pueden escribir (insert/update)
```

- `using` filtra lo existente; `with check` valida lo nuevo. UPDATE necesita ambos.
- Las políticas se combinan con OR — varias políticas permisivas se suman.
- Sin ninguna política + RLS activo = nadie accede (deny por defecto).

## Patrón 1 — Owner-based (cada usuario ve lo suyo)

```sql
create policy "users read own orders"
on public.orders for select
to authenticated
using (user_id = (select auth.uid()));

create policy "users create own orders"
on public.orders for insert
to authenticated
with check (user_id = (select auth.uid()));
```

**Performance:** envolver `auth.uid()` en `(select auth.uid())` permite a
Postgres cachearlo por statement en vez de evaluarlo por fila. Además: índice
en `user_id`.

## Patrón 2 — Multi-tenant por empresa

```sql
-- Tabla pivote usuario <-> empresa
create table public.empresa_usuarios (
  empresa_id uuid references public.empresas(id),
  user_id uuid references auth.users(id),
  role text not null default 'member',
  primary key (empresa_id, user_id)
);

-- Función helper (security definer para no recursar en RLS de la pivote)
create or replace function public.user_empresas()
returns setof uuid
language sql security definer set search_path = public
stable as $$
  select empresa_id from empresa_usuarios where user_id = auth.uid()
$$;

create policy "tenant isolation"
on public.products for all
to authenticated
using (empresa_id in (select public.user_empresas()))
with check (empresa_id in (select public.user_empresas()));
```

## Patrón 3 — Roles via JWT custom claims

```sql
-- El claim se inyecta con un Auth Hook (ver auth-patterns.md)
create policy "admins manage products"
on public.products for all
to authenticated
using ((auth.jwt() ->> 'user_role') = 'admin')
with check ((auth.jwt() ->> 'user_role') = 'admin');
```

Leer el rol del JWT (no de una tabla) evita un subquery por fila — pero el
claim solo se actualiza al renovar el token.

## Patrón 4 — Lectura pública + escritura autenticada

```sql
-- Catálogo público (landing, e-commerce)
create policy "public read active products"
on public.products for select
to anon, authenticated
using (is_active = true);

create policy "owners manage products"
on public.products for all
to authenticated
using (empresa_id in (select public.user_empresas()))
with check (empresa_id in (select public.user_empresas()));
```

Nota: el `anon` ve SOLO `is_active = true`; el dueño ve también los inactivos
porque las políticas se combinan con OR.

## Testing de políticas

```sql
-- Simular un usuario en el SQL editor / tests
set local role authenticated;
set local request.jwt.claims = '{"sub":"<uuid-del-usuario>","user_role":"admin"}';

select * from public.orders;   -- ¿retorna lo esperado?

reset role;
```

## Errores frecuentes

| Síntoma | Causa |
|---|---|
| Query retorna `[]` sin error | Política de SELECT niega — no es un bug del cliente |
| `new row violates row-level security` | Falta `with check` o el payload no cumple la condición |
| INSERT funciona pero el SELECT posterior no | Hay política de INSERT pero no de SELECT (PostgREST hace `returning`) |
| Recursión infinita en política | La política consulta una tabla que a su vez tiene RLS que consulta la primera → función `security definer` |
| Todo lento con RLS | `auth.uid()` sin `(select ...)`, falta índice en la columna filtrada |
