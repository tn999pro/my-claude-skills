# Webhook node y HTTP Request node

## Webhook node — recibir llamadas

### Configuración clave

| Opción | Recomendación |
|---|---|
| HTTP Method | El que envía el caller (POST para casi todo) |
| Path | Descriptivo y único: `pedido-creado`, no `webhook1` |
| Authentication | **Header Auth** con secret compartido — nunca "None" en producción |
| Respond | `Immediately` para callers con timeout (Meta, backend); `When Last Node Finishes` solo si el caller necesita el resultado |

### URLs de prueba vs producción
- **Test URL** (`/webhook-test/...`): solo funciona con el editor abierto y
  "Listen for test event" activo.
- **Production URL** (`/webhook/...`): requiere el workflow **Activo**.
- Error clásico: probar la URL de producción con el workflow inactivo → 404.

### Validación al recibir (primer nodo después del Webhook)
```javascript
// Code node — validar payload antes de procesar
const body = $json.body;
if (!body?.event || !body?.data?.id) {
  throw new Error(`Payload inválido: ${JSON.stringify(body).slice(0, 200)}`);
}
return $input.all();
```

## HTTP Request node — llamar APIs

### Configuración robusta
- **Authentication**: credencial de n8n (Header Auth / OAuth2) — NUNCA el
  token pegado en un header manual (se exporta con el workflow).
- **Retry on Fail**: ON, 3 intentos, 1000ms+ entre intentos.
- **Timeout**: explícito (10–30s) — el default puede colgar el workflow.
- **Response → Never Error**: solo si vas a manejar el status manualmente
  con un IF posterior; si no, dejar que falle para que actúe el Error Workflow.

### Llamar a tu backend (FastAPI/Spring)
```
Method: POST
URL: {{ $env.BACKEND_URL }}/api/webhooks/n8n/pedido-procesado
Headers (credencial Header Auth): X-Webhook-Secret: <secret>
Body JSON: {{ JSON.stringify($json) }}
```
La URL base SIEMPRE de `$env`/credencial — cambiar de staging a prod no debe
requerir editar nodos.

### Paginación de APIs
Usar la pestaña **Pagination** del nodo HTTP (n8n 1.x):
- `Response Contains Next URL` → expresión al campo `next`
- O `Update a Parameter in Each Request` (page/offset) con condición de parada
Evitar loops manuales de paginación salvo APIs muy raras.

### Subir/descargar archivos
- Descargar: HTTP Request con `Response Format: File` → el binario queda en
  `$binary.data` para el siguiente nodo.
- Subir: `Body Content Type: n8n Binary File` o `Form-Data Multipart`.

## Patrón completo: webhook → proceso → callback

```
[Webhook /pedido-nuevo]          ← Respond: Immediately (200 al caller)
  → [Code: validar payload]
  → [IF: ¿ya procesado?]         ← idempotencia: consultar por id externo
      (sí) → [NoOp: fin]
      (no) → [HTTP: consultar datos al backend]
           → [Code: transformar]
           → [HTTP: acción externa (WhatsApp, Sheets...)]
           → [HTTP: callback al backend con el resultado]
```

## Debug

- **Executions** (panel izquierdo): cada ejecución guarda el input/output de
  cada nodo — abrir la fallida y revisar el JSON nodo a nodo.
- Pin Data: fijar un payload real de ejemplo en el Webhook para iterar sin
  re-disparar el evento externo.
- `console.log` en Code nodes sale en la vista de ejecución (self-hosted:
  también en logs del contenedor).
