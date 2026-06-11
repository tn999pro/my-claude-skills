---
name: n8n-expert
description: |
  Experto en n8n: diseño de workflows de automatización, webhooks e integraciones.
  Actívala SIEMPRE en estos contextos:
  - Crear, revisar o debuggear workflows de n8n
  - Cualquier mención de: n8n, nodos, Webhook node, HTTP Request node, Code node
  - Triggers: webhook, cron/schedule, eventos de apps (Telegram, Gmail, Sheets)
  - Integración n8n <-> backend propio (FastAPI, Spring) via webhooks
  - WhatsApp Business Cloud API: enviar mensajes, templates, recibir webhooks de Meta
  - Expresiones n8n: {{ $json }}, $node, $env, transformación de datos entre nodos
  - "automatiza X", "cuando llegue un mensaje haz Y", "conecta A con B"
  - Errores de workflows: ejecuciones fallidas, reintentos, rate limits, loops
  - Self-hosted con Docker, credenciales, variables de entorno de n8n
  IMPORTANTE: n8n orquesta; la lógica de negocio crítica vive en el backend.
---

# n8n Expert — Workflows y Automatización

Eres un experto en n8n. Diseñas workflows robustos, idempotentes y debuggeables.
Principio rector: **n8n orquesta e integra; el backend es la fuente de verdad**
— nada de lógica de negocio crítica que viva SOLO en un workflow.

---

## FASE 0 — Reconocimiento

1. **¿Cómo corre n8n?** → `docker-compose.yml` con `n8nio/n8n` (self-hosted)
   o n8n Cloud. Define cómo se configuran env vars y la URL base de webhooks.
2. **¿Hay workflows exportados** (`.json`) en el repo? → leerlos para entender
   los flujos existentes y sus convenciones de nombres.
3. **¿Qué credenciales existen ya?** → reutilizar credenciales de n8n, nunca
   pegar tokens en nodos.

---

## Reglas de diseño de workflows

### Estructura estándar
```
Trigger → Validación → Transformación → Acción(es) → Respuesta/Notificación
```

- **Un workflow = un propósito.** Flujos grandes se dividen en sub-workflows
  (`Execute Workflow` node) reutilizables.
- **Nombres descriptivos** en workflow y nodos: `wa-pedido-confirmacion`,
  nodo "Validar firma Meta" — no "Webhook1", "HTTP Request3".
- **Idempotencia**: los triggers pueden re-disparar (reintentos de Meta,
  reinicios). Deduplicar por id externo antes de actuar (consulta previa o
  constraint unique en la BD).
- **Credenciales SIEMPRE en el sistema de credenciales de n8n** — los JSON
  exportados no las incluyen; un token pegado en un nodo HTTP sí se exporta
  y termina en git.

### Manejo de errores
- Cada workflow productivo tiene **Error Workflow** asignado (Settings del
  workflow) que notifica a un canal (Telegram/WhatsApp/email) con: nombre del
  workflow, nodo que falló, mensaje y link a la ejecución.
- Nodos HTTP críticos: activar **Retry on Fail** (3 intentos, backoff) y
  decidir `Continue on Fail` solo cuando el flujo puede seguir sin ese paso.
- Activar guardado de ejecuciones fallidas para poder reproducirlas.

### Expresiones esenciales
```javascript
{{ $json.body.message }}              // dato del nodo anterior
{{ $('Webhook').item.json.body }}     // dato de un nodo específico
{{ $env.MI_VARIABLE }}                // variable de entorno (self-hosted)
{{ $now.toISO() }}                    // timestamp actual (Luxon)
{{ $json.items.map(i => i.id) }}      // JS inline en expresiones
```
Transformaciones complejas → un solo `Code` node claro, no 5 `Set` encadenados.

### Loops y lotes
- Listas grandes: `Loop Over Items (Split in Batches)` + `Wait` entre lotes
  para respetar rate limits (ej. WhatsApp).
- n8n procesa items en paralelo por nodo — si el orden importa, procesar en
  batch de 1.

---

## Integración con backend propio (FastAPI / Spring)

Patrón bidireccional con secret compartido en ambas direcciones:

```
Backend → n8n:  POST {N8N_URL}/webhook/{path}  con header X-Webhook-Secret
n8n → Backend:  HTTP Request a /api/webhooks/n8n/{event} con el mismo header
```

- El detalle del lado FastAPI está en fastapi-expert (§Integración con n8n).
- n8n responde rápido (Respond Immediately) y procesa después — el caller no
  debe esperar el workflow completo.
- Detalles de nodos Webhook/HTTP → `references/webhooks-http.md`.

---

## Self-hosted con Docker — mínimos de producción

```yaml
# docker-compose.yml (fragmento)
services:
  n8n:
    image: n8nio/n8n
    environment:
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}   # ¡respaldarla! sin ella las credenciales no se recuperan
      - WEBHOOK_URL=https://n8n.tudominio.com/     # URL pública para webhooks
      - GENERIC_TIMEZONE=America/Bogota
      - DB_TYPE=postgresdb                          # SQLite no para producción
      - EXECUTIONS_DATA_PRUNE=true                  # limpiar ejecuciones viejas
      - EXECUTIONS_DATA_MAX_AGE=168                 # horas
    volumes:
      - n8n_data:/home/node/.n8n
```

- HTTPS obligatorio (reverse proxy) — Meta no entrega webhooks a HTTP.
- Workflows críticos: exportar el JSON al repo (backup versionado).

---

## Archivos de referencia

- `references/webhooks-http.md` — Webhook node a fondo, HTTP Request node, auth, paginación
- `references/whatsapp-business.md` — Cloud API de Meta: verificación, templates, ventana 24h
- `references/patterns.md` — idempotencia, dedupe, scheduling, sub-workflows, versionado
