# WhatsApp Business Cloud API (Meta) en n8n

## Conceptos que definen todo el diseño

- **Ventana de 24 horas**: tras el último mensaje del usuario tienes 24h para
  responder con texto libre. Fuera de la ventana SOLO se pueden enviar
  **templates aprobados** por Meta.
- **Templates**: se crean y aprueban en el WhatsApp Manager (horas a días).
  Tipos: utility (confirmaciones, recordatorios) y marketing (promos — más
  caros y con opt-out).
- **Webhooks de Meta**: reintentan ante fallos → el workflow DEBE ser
  idempotente (dedupe por `message.id`).

## Recibir mensajes — webhook de Meta

### 1. Verificación inicial (GET con challenge)
Meta valida la URL con un GET antes de activar el webhook:

```
[Webhook GET /wa-inbound]
  → [IF: $json.query['hub.verify_token'] == $env.WA_VERIFY_TOKEN]
      (sí) → [Respond to Webhook: $json.query['hub.challenge']]   ← texto plano
      (no) → [Respond to Webhook: 403]
```

### 2. Recepción de mensajes (POST al mismo path)
```javascript
// Code node — extraer lo útil del payload de Meta (viene muy anidado)
const entry = $json.body.entry?.[0];
const change = entry?.changes?.[0]?.value;
const message = change?.messages?.[0];

if (!message) return [];   // statuses (delivered/read) u otros eventos: ignorar o ramificar

return [{
  json: {
    messageId: message.id,            // para dedupe
    from: message.from,               // teléfono del usuario
    type: message.type,               // text | image | interactive | button
    text: message.text?.body ?? null,
    buttonReply: message.interactive?.button_reply?.id ?? null,
    timestamp: message.timestamp,
    contactName: change.contacts?.[0]?.profile?.name ?? null,
  },
}];
```

Responder 200 **inmediatamente** (Respond: Immediately) — si Meta no recibe
200 rápido, reintenta y acumula duplicados.

## Enviar mensajes — HTTP Request a Graph API

```
POST https://graph.facebook.com/v21.0/{{ $env.WA_PHONE_NUMBER_ID }}/messages
Authorization: Bearer <token>        ← credencial de n8n, no en el nodo
Content-Type: application/json
```

### Texto libre (solo dentro de la ventana 24h)
```json
{
  "messaging_product": "whatsapp",
  "to": "{{ $json.from }}",
  "type": "text",
  "text": { "body": "¡Recibimos tu pedido! Te confirmamos en minutos." }
}
```

### Template (fuera de la ventana — la única opción)
```json
{
  "messaging_product": "whatsapp",
  "to": "573001234567",
  "type": "template",
  "template": {
    "name": "confirmacion_pedido",
    "language": { "code": "es_CO" },
    "components": [{
      "type": "body",
      "parameters": [
        { "type": "text", "text": "{{ $json.clienteNombre }}" },
        { "type": "text", "text": "{{ $json.numeroPedido }}" }
      ]
    }]
  }
}
```

### Botones interactivos (dentro de ventana)
```json
{
  "messaging_product": "whatsapp",
  "to": "{{ $json.from }}",
  "type": "interactive",
  "interactive": {
    "type": "button",
    "body": { "text": "¿Confirmas tu pedido #1042?" },
    "action": { "buttons": [
      { "type": "reply", "reply": { "id": "confirm_1042", "title": "Confirmar" } },
      { "type": "reply", "reply": { "id": "cancel_1042", "title": "Cancelar" } }
    ]}
  }
}
```
La respuesta llega como `type: interactive` con `button_reply.id` — enrutar
con un Switch node por ese id.

## Errores frecuentes

| Error | Causa |
|---|---|
| `131047` Re-engagement | Ventana de 24h cerrada → usar template |
| `132001` Template not found | Nombre/idioma no coinciden con el aprobado (es_CO ≠ es) |
| `100` Invalid parameter | Teléfono sin código de país o con `+`/espacios |
| `131026` Not on WhatsApp | El número no tiene WhatsApp |
| Webhook no llega | URL sin HTTPS válido, verify token mal, o app de Meta en modo development sin el número de prueba |

## Reglas de envío masivo

- `Loop Over Items` en lotes pequeños + `Wait` 1–2s entre lotes (rate limits
  por tier del número).
- Registrar cada envío (id de mensaje, status) en la BD via backend — los
  webhooks de `statuses` (sent/delivered/read/failed) actualizan ese registro.
- Marketing siempre con opt-in registrado y opción de salida — además de ser
  política de Meta, evita bloqueos del número.
