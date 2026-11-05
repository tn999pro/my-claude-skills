# UI y Estilos — tokens HSL, Tailwind, dark premium

## Detectar el sistema antes de escribir estilos

| En el proyecto | Cómo trabajar |
|---|---|
| `tailwind.config.*` | Utilidades Tailwind; colores vía tokens del config, no arbitrarios |
| `globals.css` con `--variables` HSL | Vanilla CSS con tokens — seguir EXACTAMENTE esa paleta |
| CSS Modules (`*.module.css`) | Un módulo por componente, clases locales |

Nunca mezclar: si el proyecto es vanilla CSS (ej. vantedge), no meter Tailwind.

## Design tokens en HSL (base de ambos mundos)

```css
/* globals.css — una sola fuente de verdad para el color */
:root {
  --background: 222 47% 5%;
  --surface: 222 40% 8%;
  --border: 0 0% 100% / 0.06;
  --text-primary: 210 20% 96%;
  --text-secondary: 215 16% 65%;
  --accent: 217 91% 60%;
}

.card {
  background: hsl(var(--surface));
  border: 1px solid hsl(var(--border));
  color: hsl(var(--text-primary));
}
```

Con Tailwind, los mismos tokens se mapean en el config:
```ts
// tailwind.config.ts
colors: {
  background: 'hsl(var(--background))',
  surface: 'hsl(var(--surface))',
  accent: 'hsl(var(--accent))',
}
```

## Estética dark premium (estilo Stripe/Apple/Squarespace)

Reglas de la casa:
- **Paleta sobria en HSL** — nada de neones saturados "estilo gamer"
- **Cero emojis** como iconografía en componentes core — usar SVG (lucide)
  o mockups CSS
- **Tipografía**: display (`Space Grotesk`) para títulos con gradiente sutil,
  `Inter` para texto base; interlineado compacto en títulos

```css
/* Título con gradiente sutil — no arcoíris */
.heading {
  background: linear-gradient(135deg, #ffffff, hsl(var(--text-secondary)));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}

/* Glassmorphism premium */
.glass-card {
  background: hsl(var(--surface) / 0.6);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.05);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.25);
}
```

## Curvas de animación

```css
/* Interacción inmediata (botones, links): rápida */
transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);

/* Zoom de imágenes tipo Squarespace: lenta y elegante */
transition: transform 0.5s cubic-bezier(0.25, 1, 0.5, 1);
.image-card:hover img { transform: scale(1.05); }
```

```css
/* Respetar accesibilidad de movimiento SIEMPRE */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { transition-duration: 0.01ms !important; }
}
```

## Dark mode sin hydration mismatch

```tsx
// ❌ Leer localStorage en el render → mismatch server/client
// ✅ Script inline en <head> que setea la clase ANTES del primer paint,
//    o usar next-themes que lo resuelve:
import { ThemeProvider } from 'next-themes';

<ThemeProvider attribute="class" defaultTheme="dark">
  {children}
</ThemeProvider>
// y suppressHydrationWarning en <html>
```

## Responsive — reglas mínimas

- Mobile-first: estilos base para móvil, `min-width` para escalar
- Grillas con breakpoints reales: verificar que precios, botones y títulos
  no se solapen ni partan raro en 360px de ancho
- Targets táctiles ≥ 44px en móvil
- Texto base ≥ 16px (evita zoom automático de iOS en inputs)

## Accesibilidad básica no negociable

- Contraste AA: 4.5:1 texto normal, 3:1 texto grande — verificar
  `--text-secondary` sobre `--background`
- Estados `:focus-visible` visibles (no `outline: none` sin reemplazo)
- Botones con texto o `aria-label`; inputs con `<label>`
