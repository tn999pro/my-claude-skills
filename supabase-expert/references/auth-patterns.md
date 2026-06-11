# Auth — Patrones

## Métodos de autenticación

```typescript
// Email + password
await supabase.auth.signUp({ email, password });
await supabase.auth.signInWithPassword({ email, password });

// Magic link / OTP por email (sin contraseña)
await supabase.auth.signInWithOtp({ email, options: { emailRedirectTo: url } });

// OAuth (Google, GitHub...) — configurar el provider en el dashboard
await supabase.auth.signInWithOAuth({
  provider: 'google',
  options: { redirectTo: `${origin}/auth/callback` },
});

await supabase.auth.signOut();
```

En Next.js usar SIEMPRE los clientes de `@supabase/ssr` (sesión en cookies)
→ nextjs-expert/references/supabase-ssr.md.

## Tabla profiles — datos de usuario propios

`auth.users` es del sistema — no agregarle columnas. Los datos de la app van
en `public.profiles` creada automáticamente con un trigger:

```sql
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  avatar_url text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "users read own profile" on public.profiles
  for select to authenticated using (id = (select auth.uid()));
create policy "users update own profile" on public.profiles
  for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

-- Trigger: crear el profile al registrarse
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

## Roles con custom claims (Auth Hook)

Para que las políticas RLS lean el rol del JWT sin subqueries:

```sql
create table public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'member'   -- member | admin | superadmin
);

-- Custom Access Token Hook (activar en Dashboard → Auth → Hooks)
create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb language plpgsql stable as $$
declare
  claims jsonb := event -> 'claims';
  user_role text;
begin
  select role into user_role from public.user_roles
    where user_id = (event ->> 'user_id')::uuid;
  claims := jsonb_set(claims, '{user_role}', to_jsonb(coalesce(user_role, 'member')));
  return jsonb_set(event, '{claims}', claims);
end;
$$;
```

```sql
-- En las políticas:
using ((auth.jwt() ->> 'user_role') = 'admin')
```

⚠️ El claim se actualiza al RENOVAR el token — tras cambiar un rol, forzar
`supabase.auth.refreshSession()` o esperar la expiración del access token.

## Configuración que siempre se olvida

- **Redirect URLs** (Dashboard → Auth → URL Configuration): agregar TODAS las
  URLs de callback (localhost, staging, prod) o el OAuth/magic link falla.
- **Email templates**: personalizar antes de producción (los default delatan
  el proyecto).
- **Expiración del access token**: 1 h por defecto está bien; el refresh es
  automático en los SDKs.
- **Confirmación de email**: activada por defecto — en desarrollo puede
  desactivarse para iterar rápido, reactivar en producción.

## Seguridad

- `getUser()` (valida contra el servidor) para decisiones de autorización;
  `getSession()` solo para UX optimista.
- Nunca confiar en datos de `user_metadata` para autorización — el usuario
  puede modificarlos. Roles SIEMPRE en tabla propia o `app_metadata`.
- Rate limits de auth: configurables en el dashboard — subir los de OTP si
  el flujo de magic links es el principal.
