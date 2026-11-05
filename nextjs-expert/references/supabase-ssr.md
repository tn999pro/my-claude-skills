# Supabase en Next.js — @supabase/ssr

Tres clientes según el contexto. La sesión vive en cookies (no localStorage)
para que los Server Components puedan leerla.

## Cliente de navegador (Client Components)

```tsx
// lib/supabase/client.ts
import { createBrowserClient } from '@supabase/ssr';

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
```

## Cliente de servidor (RSC, Server Actions, Route Handlers)

```tsx
// lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function createClient() {
  const cookieStore = await cookies();
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => cookieStore.getAll(),
        setAll: (cookiesToSet) => {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options));
          } catch {
            // setAll desde un RSC lanza — lo maneja el middleware
          }
        },
      },
    },
  );
}
```

## Middleware — refresca la sesión en cada request

```tsx
// middleware.ts (raíz del proyecto)
import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({ request });
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: (cookiesToSet) => {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
          response = NextResponse.next({ request });
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options));
        },
      },
    },
  );

  // IMPORTANTE: getUser() valida contra el servidor de Supabase.
  // getSession() solo lee la cookie (falsificable) — NO usarla para proteger rutas.
  const { data: { user } } = await supabase.auth.getUser();

  if (!user && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  return response;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg)$).*)'],
};
```

## Datos en Server Components

```tsx
export default async function DashboardPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect('/login');

  // RLS aplica automáticamente con la sesión del usuario
  const { data: orders, error } = await supabase
    .from('orders')
    .select('*, items:order_items(*)')
    .order('created_at', { ascending: false })
    .range(0, 19);

  if (error) throw error;   // lo captura error.tsx
  return <OrdersTable orders={orders} />;
}
```

## service_role — solo en el servidor, solo cuando RLS estorba

```tsx
// lib/supabase/admin.ts — SOLO importar desde código de servidor
import { createClient } from '@supabase/supabase-js';

export const supabaseAdmin = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,   // SIN prefijo NEXT_PUBLIC_
  { auth: { persistSession: false } },
);
```
Usos legítimos: jobs administrativos, webhooks, agregaciones cross-tenant.
Nunca para "arreglar" un RLS que niega acceso — eso es un bug de políticas.

## Reglas

- RLS habilitado en TODA tabla que toque el cliente — la anon key es pública.
- `getUser()` para decisiones de seguridad; `getSession()` solo para UX.
- Errores de Supabase: si `data` llega vacío sin error, sospechar de políticas RLS.
