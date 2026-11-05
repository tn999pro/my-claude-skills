# Prompts de generación y guiones

## Estructura de guion universal (cualquier formato)

```
GANCHO (2-3s / primera línea)
  Pregunta o dato que duele: "¿Sigue contando su inventario en un cuaderno?"
DOLOR (desarrollo corto)
  El costo real: tiempo, ventas perdidas, errores — en pesos si se puede
SOLUCIÓN (sin jerga)
  Qué cambia con el sistema — mostrado, no descrito
CTA (cierre)
  Una sola acción: "Escríbanos por WhatsApp" + beneficio de hacerlo ya
```

Anti-patrón: empezar por la empresa ("En Vantedge desarrollamos...") — a
nadie le importa hasta que el dolor conectó.

## Guion de reel (15-30s) — plantilla

```markdown
**Pieza:** <nombre> | **Pilar:** <educar/demostrar/convertir> | **Dolor:** <cuál>

| Tiempo | Visual | Texto en pantalla / VO |
|---|---|---|
| 0-2s | <gancho visual: problema en acción> | "<pregunta que duele>" |
| 2-10s | <el dolor: caos, cuaderno, pedidos perdidos> | <2 frases máximo> |
| 10-22s | <demo real del producto en uso> | "<qué cambia, en lenguaje simple>" |
| 22-30s | <logo + número> | "Escríbanos por WhatsApp → <número>" |
```

## Prompts para video generativo (Higgsfield y similares)

Estructura del prompt: **sujeto + acción + entorno + estilo + cámara + luz**.
El estilo Vantedge se especifica SIEMPRE — sin él, la IA tira a genérico saturado.

```text
# Bloque de estilo Vantedge (anexar a todo prompt de video/imagen)
Style: premium, sober, minimal. Dark background with deep navy tones,
soft studio lighting, shallow depth of field. Clean composition,
no neon colors, no cartoon style, no text overlays.
Mood: professional, calm, trustworthy. Cinematic 4k.
```

```text
# Ejemplo — escena de dolor (retail)
A small shop owner in Colombia flipping through a worn paper notebook
surrounded by shoe boxes, looking stressed, warm dim lighting,
handheld camera slowly pushing in. [+ bloque de estilo]
```

```text
# Ejemplo — escena de solución
Close-up of hands holding a smartphone photographing a sneaker;
the screen shows a clean dark inventory app confirming the product.
Smooth gimbal movement, soft rim light. [+ bloque de estilo]
```

Reglas:
- **Nunca pedir texto dentro del video generado** (la IA lo deforma) — el
  texto va como overlay en edición.
- Personas: planos medios/cerrados y manos funcionan mejor que rostros
  protagonistas (uncanny valley) — para rostros, mejor material real.
- Generar 3-4 variaciones del mismo prompt y elegir; el costo está en la
  selección, no en la generación.
- Las capturas del producto SIEMPRE son reales (del dashboard/app de verdad)
  — la IA genera contexto y ambiente, no la prueba del producto.

## Prompts para imagen (carruseles, posts)

```text
# Fondo para lámina de carrusel
Abstract dark premium background, deep navy gradient with subtle
glassmorphism shapes, soft glow, minimal, lots of negative space
for text overlay, 4:5 aspect ratio.
```

El texto de las láminas se monta encima (Canva/Figma/CSS) con la tipografía
de marca — nunca generado dentro de la imagen.

## Copy por canal — el mismo guion, tres salidas

**Carrusel (de un reel existente):** gancho = lámina 1; dolor = láminas 2-3;
solución = láminas 4-5 (capturas reales); lámina final = CTA WhatsApp.

**Broadcast WhatsApp (del mismo guion):**
```text
<Gancho como pregunta directa>

<Dolor en 1 frase + costo>

<Solución en 1 frase>

¿Le interesa verlo con sus productos? Responda este mensaje y le
mostramos una demo de 10 minutos. 📱
```
(Tono directo y personal — es un mensaje, no un anuncio. Solo a opt-in.)

## Specs técnicas por plataforma

| Plataforma | Formato | Resolución | Duración | Safe zones |
|---|---|---|---|---|
| IG Reels / Stories | 9:16 | 1080×1920 | 15-30s (reels) | Evitar 250px sup. e inf. (UI de IG tapa) |
| IG Carrusel | 4:5 | 1080×1350 | 5-7 láminas | Texto centrado, margen 100px |
| IG Feed | 1:1 | 1080×1080 | — | — |
| WhatsApp | libre | ≤16MB video | ≤45s ideal | Que se entienda sin contexto |
| Telegram | libre | — | — | Primer renglón = preview del canal |

## Checklist antes de pasar al gate de aprobación

- [ ] Gancho en los primeros 2 segundos / primera línea
- [ ] Cero jerga técnica (regla de tech-proposals: traducir a negocio)
- [ ] CTA único a WhatsApp con link/número correcto
- [ ] Subtítulos en video (se consume sin audio)
- [ ] Sin texto generado por IA dentro del asset
- [ ] Capturas del producto reales y actualizadas
- [ ] Estilo Vantedge: sobrio, oscuro, sin neones ni emojis infantiles
