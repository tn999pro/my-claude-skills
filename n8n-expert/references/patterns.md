# Patrones de workflows robustos

## Idempotencia y deduplicación

Todo trigger puede dispararse dos veces (reintentos de Meta, redeploys,
clicks dobles). Antes de cualquier acción con efectos:

```
[Trigger] → [HTTP: GET backend /events/{externalId}/exists]
          → [IF exists]
              (sí) → fin silencioso
              (no) → procesar → [HTTP: registrar externalId procesado]
```

Alternativa sin backend: tabla `processed_events(external_id unique)` en
Supabase/Postgres — el INSERT con conflicto detecta el duplicado:
`on conflict do nothing` + revisar filas afectadas.

## Error Workflow centralizado

Un único workflow `_error-handler` asignado como Error Workflow de todos los
flujos productivos:

```
[Error Trigger]
  → [Code: formatear]   // workflow, nodo, mensaje, executionUrl
  → [WhatsApp/Telegram: notificar al canal de alertas]
```

```javascript
// Datos disponibles en el Error Trigger
const e = $json;
return [{ json: {
  workflow: e.workflow.name,
  node: e.execution?.lastNodeExecuted,
  error: e.execution?.error?.message,
  url: e.execution?.url,
  at: $now.toISO(),
}}];
```

## Scheduling — Schedule Trigger

- Cron con timezone explícita (self-hosted: `GENERIC_TIMEZONE=America/Bogota`).
- Jobs programados también deben ser idempotentes: si el job de las 8:00 no
  corrió (servidor caído), ¿el de las 9:00 procesa lo pendiente o se pierde?
  → diseñar por "procesar todo lo pendiente", no por "procesar lo de esta hora".
- Evitar solapamiento: si una corrida puede tardar más que el intervalo,
  marcar "en proceso" al inicio (flag en BD) y salir si ya hay una activa.

## Sub-workflows (Execute Workflow)

Extraer a sub-workflow cuando:
- La misma secuencia aparece en 2+ workflows (ej. "enviar WhatsApp con retry")
- Un flujo supera ~20 nodos y tiene secciones con nombre propio

```
[Execute Workflow: wa-send]   ← recibe { to, template, params }, retorna { messageId }
```
Convención: prefijo `_` para sub-workflows y utilitarios (`_wa-send`,
`_error-handler`) — los distingue de los flujos de negocio.

## Transformación de datos — Code node

```javascript
// Modo "Run Once for All Items" — agregaciones
const items = $input.all();
const total = items.reduce((sum, i) => sum + i.json.amount, 0);
return [{ json: { total, count: items.length } }];

// Modo "Run Once for Each Item" — mapeo 1:1
const d = $input.item.json;
return { json: { nombre: d.name?.trim(), precio: Number(d.price) || 0 } };
```
Preferir un Code node claro sobre cadenas de Set/IF/Merge ilegibles. Pero si
un nodo nativo existe (Filter, Sort, Remove Duplicates), usarlo — es más
legible en el canvas.

## Rate limiting hacia APIs externas

```
[Loop Over Items (batch: 5)]
  → [HTTP Request (Retry on Fail: 3)]
  → [Wait: 1s]
  → (loop)
```
Para APIs con headers `Retry-After`: capturar el 429 (Continue on Fail) y
un IF que espera lo indicado antes de reintentar.

## Versionado y backup de workflows

- Workflows críticos: exportar JSON al repo del proyecto
  (`automations/n8n/<nombre>.json`) en cada cambio relevante — el JSON no
  incluye credenciales, sí incluye todo lo demás.
- Convención de nombres: `<dominio>-<acción>` (`pedidos-confirmacion-wa`,
  `inventario-sync-diario`).
- Cambios grandes: duplicar el workflow (`v2`), probar con Pin Data, activar
  el nuevo y desactivar el viejo — no editar en caliente el productivo.

## Checklist antes de activar un workflow

- [ ] Webhook con autenticación (header secret) — no endpoints abiertos
- [ ] Error Workflow asignado
- [ ] Idempotencia ante re-disparos
- [ ] Credenciales del sistema de n8n (nada hardcodeado en nodos)
- [ ] URLs base desde `$env`, no literales
- [ ] Probado con Pin Data de un payload real
- [ ] JSON exportado al repo si es crítico
