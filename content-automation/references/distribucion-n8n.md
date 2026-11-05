# Distribución automatizada con n8n

Mecánica de nodos, credenciales y patrones de robustez → skill **n8n-expert**.
Aquí: los workflows específicos del pipeline de contenido.

## Arquitectura

```
[Calendario (Sheets/Supabase)] ← fuente de verdad de qué se publica cuándo
        │
[n8n: Schedule Trigger diario]
        │
[¿Hay pieza programada hoy?] ──no──> fin
        │ sí
[GATE: enviar preview por Telegram y ESPERAR aprobación]
        │ aprobada
[Switch por canal] → [Instagram] / [Telegram] / [WhatsApp broadcast]
        │
[Registrar publicación + programar recordatorio de métricas]
```

## El calendario como fuente (Supabase o Sheets)

Tabla `content_calendar`:

| Campo | Ejemplo |
|---|---|
| `id` | uuid |
| `titulo` | "Reel — inventario en cuaderno" |
| `pilar` | educar / demostrar / convertir |
| `canal` | instagram_reel / instagram_carrusel / whatsapp / telegram |
| `fecha_publicacion` | 2026-06-12 |
| `asset_url` | URL en Supabase Storage |
| `copy` | texto/caption final |
| `estado` | borrador / pendiente_aprobacion / aprobada / publicada / fallida |
| `pieza_origen_id` | id de la pieza de la que se repurposeó (null si es original) |
| `metricas` | jsonb (se llena después) |

`pieza_origen_id` permite auditar la regla de repurposing: una pieza original
sin al menos 2 hijas = cadena incompleta.

## Gate de aprobación manual (obligatorio)

```
[Telegram: enviar asset + copy + botones inline "✅ Publicar" / "❌ Rechazar"]
  → [Wait: On Webhook Call]        ← el workflow se pausa
  → [Telegram Trigger: callback del botón]
  → [IF aprobada] → publicar | [IF rechazada] → estado=borrador + notificar
```

- Implementación simple: `Wait` node en modo webhook + botones con
  `callback_data` que llaman al resume-URL.
- Timeout de 24h: si no hay respuesta, NO publicar — marcar `pendiente` y
  re-notificar. El default siempre es no publicar.

## Publicar en Instagram (Graph API)

Requisitos: cuenta Business/Creator vinculada a página de Facebook, app de
Meta con `instagram_content_publish`.

Flujo de 2 pasos (ambos con HTTP Request node):
```
1. POST /{ig-user-id}/media
   { video_url | image_url, caption, media_type: REELS si aplica }
   → retorna creation_id
2. POST /{ig-user-id}/media_publish  { creation_id }
```
- Para REELS: tras el paso 1, poll a `/{creation_id}?fields=status_code`
  hasta `FINISHED` (loop con Wait 10s, máx 10 intentos) antes del paso 2.
- El asset debe estar en una URL pública (Supabase Storage público o signed
  URL de larga duración).
- Errores comunes: video fuera de specs (re-codificar 1080×1920 H.264),
  permisos de la app no aprobados por Meta.

## Telegram (lo más simple — empezar por aquí)

```
[Telegram node: Send Photo/Video] → chat_id del canal, caption con el copy
```
Bot creado con @BotFather, agregado como admin del canal. Sin proceso de
aprobación de terceros — ideal para validar el pipeline completo antes de
pelear con la API de Meta.

## WhatsApp broadcast

Detalle de la Cloud API (ventana 24h, templates, errores) →
n8n-expert/references/whatsapp-business.md. Reglas específicas de contenido:

- **Solo a lista opt-in** registrada (quién aceptó, cuándo) — enviar promos
  a quien no aceptó quema el número y viola políticas de Meta.
- Fuera de ventana 24h (lo normal en broadcast) → **template aprobado** tipo
  marketing, con variables para personalizar nombre/negocio.
- Lotes pequeños: `Loop Over Items` (batch 10-20) + `Wait` 2-5s — el tier
  del número limita envíos/día.
- Registrar respuestas: quien responde entra en ventana 24h → el seguimiento
  es conversación de venta (humana), no más broadcast.

## Registro post-publicación

```
[HTTP/Supabase: estado=publicada, published_at, permalink]
[Schedule: en 7 días → recordatorio de capturar métricas de la pieza]
```

## Orden de implementación recomendado

1. Calendario en Supabase + workflow Telegram con gate (pipeline completo, baja fricción)
2. WhatsApp broadcast a lista pequeña de prueba
3. Instagram Graph API (el que más burocracia de Meta requiere)
