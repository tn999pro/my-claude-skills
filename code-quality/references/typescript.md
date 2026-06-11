# Reglas específicas — TypeScript / JavaScript / React / Next.js

## 🔴 CRÍTICO

### any en TypeScript
```typescript
// ❌ Pierde toda la seguridad de tipos
async function processData(data: any) { ... }

// ✅ Tipos explícitos
interface ProductData { id: string; name: string; price: number; }
async function processData(data: ProductData): Promise<ProcessedResult> { ... }
```

### Variables de entorno sin validación
```typescript
// ❌ Falla en runtime con error críptico
const apiUrl = process.env.VITE_API_URL; // puede ser undefined

// ✅ Validar al inicio
const apiUrl = process.env.VITE_API_URL;
if (!apiUrl) throw new Error('VITE_API_URL no está definida');
```

### Secrets expuestos al cliente
```typescript
// ❌ En Next.js, NEXT_PUBLIC_* se incluye en el bundle del navegador
NEXT_PUBLIC_SUPABASE_SERVICE_ROLE_KEY=...  // ¡expuesto a cualquiera!

// ✅ Secrets solo en variables sin NEXT_PUBLIC_ y usados solo en
// Server Components, Route Handlers o Server Actions
SUPABASE_SERVICE_ROLE_KEY=...
```

### Promise sin catch
```typescript
// ❌ Unhandled promise rejection
fetchProducts().then(setProducts);

// ✅
try {
  const products = await fetchProducts();
  setProducts(products);
} catch (err) {
  setError(err instanceof Error ? err.message : 'Error desconocido');
}
```

---

## 🟡 MEDIO

### useEffect sin cleanup
```typescript
// ❌ Memory leak si el componente se desmonta
useEffect(() => {
  const interval = setInterval(fetchData, 5000);
}, []);

// ✅
useEffect(() => {
  const interval = setInterval(fetchData, 5000);
  return () => clearInterval(interval); // cleanup
}, []);
```

### console.log en producción
```typescript
// ❌
console.log('User data:', userData);

// ✅ Logger condicional o eliminar antes del build
if (import.meta.env.DEV) console.log('User data:', userData);
```

---

## Next.js (App Router)

### 🔴 Hydration mismatches
El HTML del servidor debe coincidir con el primer render del cliente.

```tsx
// ❌ localStorage/window/Date.now()/Math.random() en el render inicial
function ThemeWrapper({ children }) {
  const theme = localStorage.getItem('theme'); // crash en server + mismatch
  return <div data-theme={theme}>{children}</div>;
}

// ✅ Estado inicial estable + actualizar en useEffect (solo cliente)
function ThemeWrapper({ children }) {
  const [theme, setTheme] = useState('dark');
  useEffect(() => {
    setTheme(localStorage.getItem('theme') ?? 'dark');
  }, []);
  return <div data-theme={theme}>{children}</div>;
}
```

### 🟡 'use client' innecesario
```tsx
// ❌ Página entera como Client Component — pierde SSR, streaming y SEO
'use client'
export default function Page() { /* todo el árbol es cliente */ }

// ✅ Server Component por defecto; 'use client' solo en las hojas
// interactivas (botones, formularios, widgets con estado)
export default async function Page() {
  const products = await getProducts(); // fetch en el servidor
  return <ProductGrid products={products} />; // ProductGrid puede ser server
}
```

### 🟡 Fetch en useEffect cuando hay App Router
```tsx
// ❌ Patrón de pages/ arrastrado a app/
'use client'
useEffect(() => { fetch('/api/products').then(...) }, []);

// ✅ Async Server Component — datos en el servidor, sin spinner
export default async function Page() {
  const products = await getProducts();
  return <List items={products} />;
}
```

### 🟢 SEO y metadatos
```tsx
// ✅ Metadata API en vez de <head> manual
export const metadata: Metadata = {
  title: 'Catálogo | Mi Tienda',
  description: '...',
};

// ✅ Dinámico
export async function generateMetadata({ params }): Promise<Metadata> { ... }

// ✅ JSON-LD para datos estructurados
<script
  type="application/ld+json"
  dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
/>
```

### 🟢 Imágenes y fuentes
```tsx
// ✅ next/image en vez de <img> (lazy loading, tamaños, formatos)
<Image src={url} alt="..." width={400} height={300} />

// ✅ next/font en vez de <link> a Google Fonts (sin layout shift)
import { Inter } from 'next/font/google';
```
