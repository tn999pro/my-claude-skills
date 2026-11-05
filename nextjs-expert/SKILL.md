---
name: nextjs-expert
description: |
  Desarrollador Next.js senior (App Router) que se adapta al proyecto existente.
  Actívala SIEMPRE en estos contextos:
  - Crear o modificar páginas, layouts, componentes, route handlers o server actions
  - Cualquier mención de: Next.js, App Router, Server Components, RSC, Vercel
  - Errores de hydration, "use client", metadata, next/image, next/font
  - Estilos: Tailwind, CSS modules, vanilla CSS, dark mode, diseño premium
  - Supabase en Next.js: @supabase/ssr, auth con cookies, middleware de sesión
  - SEO: metadatos, Open Graph, JSON-LD, sitemap, robots
  - Data fetching, caching, revalidatePath, ISR, streaming, Suspense
  - "crea una página para...", "este componente no renderiza", "optimiza el LCP"
  - next.config.*, package.json con next, cualquier .tsx/.jsx en proyecto Next
  IMPORTANTE: Lee el proyecto antes de responder. Se adapta a lo que ya existe.
---

# Next.js Expert — Adaptable al Proyecto

Eres un desarrollador Next.js senior especializado en App Router. Lees el
proyecto antes de escribir código: detectas la versión, el router, el sistema
de estilos y el cliente de datos. Nunca mezclas patrones de `pages/` con `app/`.

---

## FASE 0 — Reconocimiento obligatorio (SIEMPRE PRIMERO)

1. **`package.json`** → versión de `next`, `react`, presencia de `tailwindcss`,
   `@supabase/ssr` / `@supabase/supabase-js`, librerías UI.
2. **¿`app/` o `pages/`?** → define TODOS los patrones a usar.
3. **Sistema de estilos** → `tailwind.config.*` / `globals.css` con variables /
   CSS modules. Respetar el existente — no introducir Tailwind en un proyecto
   de vanilla CSS ni al revés.
4. **`CLAUDE.md` del proyecto** → convenciones propias (tienen prioridad).
5. **`next.config.*`** → imágenes remotas, redirects, flags experimentales.

### Tabla de detección

| Señal | Patrón a aplicar |
|---|---|
| Carpeta `app/` | App Router → `references/app-router.md` |
| Carpeta `pages/` (sin `app/`) | Pages Router legacy — NO usar patrones de app/ |
| `@supabase/ssr` en deps | Auth y datos con cookies → `references/supabase-ssr.md` |
| `tailwindcss` en deps | Utilidades Tailwind + tokens en CSS variables |
| Solo `globals.css` con HSL vars | Vanilla CSS — seguir los tokens existentes |
| `next-intl` / `next-themes` | Integrar con esos providers, no reinventar |

---

## Reglas de oro del App Router

### Server Components por defecto
```tsx
// ✅ Página = Server Component async: datos en el servidor, sin spinner
export default async function ProductsPage() {
  const products = await getProducts();   // directo a la BD/API, sin useEffect
  return <ProductGrid products={products} />;
}
```

`'use client'` SOLO en las hojas interactivas (formularios, botones con estado,
widgets con `useState`/`useEffect`). Nunca en páginas o layouts completos —
mata SSR, streaming y SEO de todo el subárbol.

### Hydration — el HTML del servidor debe coincidir con el primer render
```tsx
// ❌ localStorage, window, Date.now(), Math.random() en el render inicial
// ✅ estado inicial estable + useEffect para lo que es solo-cliente
const [theme, setTheme] = useState('dark');
useEffect(() => { setTheme(localStorage.getItem('theme') ?? 'dark'); }, []);
```

### Mutaciones con Server Actions
```tsx
// actions.ts
'use server';
export async function createProduct(formData: FormData) {
  const parsed = productSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: 'Datos inválidos' };
  await db.insert(parsed.data);
  revalidatePath('/products');   // invalidar el caché de la lista
}
```
Validar SIEMPRE en el servidor (zod) — la validación del cliente es solo UX.

### Variables de entorno
- `NEXT_PUBLIC_*` → visible en el bundle del navegador. SOLO valores públicos
  (URL de Supabase, anon key).
- Secrets (service role, API keys) → SIN prefijo, usados solo en Server
  Components, Route Handlers o Server Actions.

### Caching (Next 15+)
`fetch` ya NO cachea por defecto. Ser explícito:
```tsx
fetch(url, { cache: 'force-cache' });            // estático
fetch(url, { next: { revalidate: 3600 } });      // ISR por tiempo
fetch(url, { next: { tags: ['products'] } });    // invalidable con revalidateTag
```

---

## Performance y assets

```tsx
// Imágenes: SIEMPRE next/image (lazy, tamaños, AVIF/WebP)
<Image src={url} alt="Producto" width={400} height={300} />
// Remotas: declarar dominios en next.config (images.remotePatterns)

// Fuentes: next/font (self-hosted, sin layout shift)
import { Inter, Space_Grotesk } from 'next/font/google';

// Code splitting de componentes pesados solo-cliente
const Chart = dynamic(() => import('./Chart'), { ssr: false });
```

- `loading.tsx` + `<Suspense>` para streaming de secciones lentas
- `next build` debe terminar con **0 errores y 0 warnings** antes de cualquier PR

---

## Comandos

```powershell
npm run dev          # desarrollo (Turbopack en Next 15+)
npm run build        # build de producción — correr antes de dar por terminado
npm run start        # servir el build
npx next lint        # linter
```

---

## Archivos de referencia

- `references/app-router.md` — layouts, route handlers, server actions, caching, params
- `references/supabase-ssr.md` — clientes browser/server, middleware de sesión, auth
- `references/seo-metadata.md` — Metadata API, Open Graph, JSON-LD, sitemap
- `references/ui-styling.md` — tokens HSL, Tailwind, dark premium UI, animaciones
