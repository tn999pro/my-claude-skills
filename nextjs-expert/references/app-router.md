# App Router — Patrones

## Archivos especiales por segmento

```
app/
  layout.tsx        ← envuelve todo (html/body solo en el root layout)
  page.tsx          ← la página
  loading.tsx       ← UI de carga automática (Suspense boundary del segmento)
  error.tsx         ← error boundary ('use client' obligatorio)
  not-found.tsx     ← 404 del segmento (se dispara con notFound())
  products/
    page.tsx
    [id]/
      page.tsx      ← ruta dinámica
```

## Params y searchParams (Next 15: son Promise)

```tsx
export default async function ProductPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ page?: string }>;
}) {
  const { id } = await params;
  const { page = '1' } = await searchParams;

  const product = await getProduct(id);
  if (!product) notFound();   // dispara not-found.tsx
  return <ProductDetail product={product} />;
}
```

## Route Handlers — API endpoints

```tsx
// app/api/products/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  const page = request.nextUrl.searchParams.get('page') ?? '1';
  const products = await getProducts(Number(page));
  return NextResponse.json(products);
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const parsed = productSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 422 });
  }
  const created = await createProduct(parsed.data);
  return NextResponse.json(created, { status: 201 });
}
```

Usarlos para: webhooks externos (n8n, pagos), endpoints consumidos por otros
clientes. Para mutaciones desde la propia UI → Server Actions.

## Server Actions — mutaciones desde la UI

```tsx
// app/products/actions.ts
'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';

export async function createProduct(prevState: State, formData: FormData) {
  const parsed = productSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) {
    return { error: 'Revisa los campos marcados', fields: parsed.error.flatten() };
  }
  await db.products.create(parsed.data);
  revalidatePath('/products');
  redirect('/products');
}
```

```tsx
// Componente cliente con estado de envío
'use client';
import { useActionState } from 'react';

export function ProductForm() {
  const [state, formAction, isPending] = useActionState(createProduct, initialState);
  return (
    <form action={formAction}>
      {/* campos */}
      <button disabled={isPending}>{isPending ? 'Guardando…' : 'Guardar'}</button>
      {state.error && <p role="alert">{state.error}</p>}
    </form>
  );
}
```

## Caching e invalidación

```tsx
// Por tiempo (ISR)
export const revalidate = 3600;            // a nivel de página/segmento
fetch(url, { next: { revalidate: 3600 } }); // a nivel de fetch

// Por tag — invalidación quirúrgica desde una action o webhook
fetch(url, { next: { tags: ['products'] } });
revalidateTag('products');

// Por ruta
revalidatePath('/products');

// Forzar dinámico (datos por-request: cookies, auth)
export const dynamic = 'force-dynamic';
```

Webhook de revalidación (para CMS/backend externo que avisa de cambios):
```tsx
// app/api/revalidate/route.ts — proteger con secret
export async function POST(request: NextRequest) {
  if (request.headers.get('x-revalidate-secret') !== process.env.REVALIDATE_SECRET) {
    return NextResponse.json({ error: 'No autorizado' }, { status: 401 });
  }
  const { path } = await request.json();
  revalidatePath(path);
  return NextResponse.json({ revalidated: true });
}
```

## Streaming con Suspense

```tsx
export default function Page() {
  return (
    <>
      <Header />                              {/* render inmediato */}
      <Suspense fallback={<ProductsSkeleton />}>
        <ProductList />                       {/* RSC async lento — llega después */}
      </Suspense>
    </>
  );
}
```

## Composición server/client

- Un Client Component NO puede importar un Server Component — pero sí
  recibirlo como `children`/prop:
```tsx
// ✅ El provider es cliente, el contenido sigue siendo server
<ThemeProvider>{children}</ThemeProvider>
```
- Props de server → client deben ser serializables (no funciones, no Date sin
  convertir, no instancias de clase).
