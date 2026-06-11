# SEO en Next.js — Metadata, JSON-LD, sitemap

## Metadata API

```tsx
// app/layout.tsx — base del sitio
export const metadata: Metadata = {
  metadataBase: new URL('https://www.tudominio.com'),
  title: {
    default: 'Vantedge — Software a la medida',
    template: '%s | Vantedge',          // las páginas hijas solo ponen su parte
  },
  description: 'Desarrollo de software B2B...',
  openGraph: {
    type: 'website',
    locale: 'es_CO',
    siteName: 'Vantedge',
    images: [{ url: '/og-image.png', width: 1200, height: 630 }],
  },
  robots: { index: true, follow: true },
};
```

```tsx
// Página estática
export const metadata: Metadata = {
  title: 'Servicios',
  description: 'Soluciones de software para empresas...',
};

// Página dinámica
export async function generateMetadata(
  { params }: { params: Promise<{ slug: string }> },
): Promise<Metadata> {
  const { slug } = await params;
  const product = await getProduct(slug);
  if (!product) return { title: 'No encontrado' };
  return {
    title: product.name,
    description: product.seoDescription,
    openGraph: { images: [{ url: product.imageUrl }] },
    alternates: { canonical: `/productos/${slug}` },
  };
}
```

## JSON-LD — datos estructurados

```tsx
// Componente reutilizable
function JsonLd({ data }: { data: Record<string, unknown> }) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(data) }}
    />
  );
}

// Página de inicio de una agencia/servicio profesional
const jsonLd = {
  '@context': 'https://schema.org',
  '@type': 'ProfessionalService',
  name: 'Vantedge',
  url: 'https://www.tudominio.com',
  areaServed: 'CO',
  description: '...',
};

// Producto (e-commerce / landing de producto)
const productJsonLd = {
  '@context': 'https://schema.org',
  '@type': 'Product',
  name: product.name,
  image: product.imageUrl,
  offers: {
    '@type': 'Offer',
    price: product.price,
    priceCurrency: 'COP',
    availability: product.inStock
      ? 'https://schema.org/InStock'
      : 'https://schema.org/OutOfStock',
  },
};
```
Validar con https://search.google.com/test/rich-results antes del deploy.

## sitemap.ts y robots.ts (generados, no estáticos)

```tsx
// app/sitemap.ts
import type { MetadataRoute } from 'next';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const products = await getPublishedProducts();
  return [
    { url: 'https://www.tudominio.com', changeFrequency: 'monthly', priority: 1 },
    { url: 'https://www.tudominio.com/servicios', priority: 0.8 },
    ...products.map((p) => ({
      url: `https://www.tudominio.com/productos/${p.slug}`,
      lastModified: p.updatedAt,
      priority: 0.6,
    })),
  ];
}

// app/robots.ts
export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: '*', allow: '/', disallow: ['/dashboard/', '/api/'] },
    sitemap: 'https://www.tudominio.com/sitemap.xml',
  };
}
```

## Checklist SEO antes del deploy

- [ ] `title` y `description` únicos por página (template en el root layout)
- [ ] `metadataBase` definido (sin él, las URLs de OG salen relativas)
- [ ] Open Graph image 1200×630 — se ve al compartir por WhatsApp/LinkedIn
- [ ] JSON-LD válido en páginas clave (inicio, productos, servicios)
- [ ] `alternates.canonical` en páginas con query params o variantes
- [ ] sitemap.ts incluye el contenido dinámico publicado
- [ ] Un solo `<h1>` por página; jerarquía h2/h3 coherente
- [ ] Imágenes con `alt` descriptivo (también es accesibilidad)
