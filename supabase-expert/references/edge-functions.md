# Edge Functions — Deno

## Cuándo usarlas (y cuándo no)

✅ Webhooks receptores (pagos, Meta/WhatsApp, n8n), lógica ligera cerca de la
BD, tareas que necesitan `service_role` sin exponer un backend.
❌ Lógica de negocio central (eso va en tu backend), procesos largos (límite
de ejecución), todo lo que ya hace n8n mejor (orquestación multi-servicio).

## Estructura y creación

```powershell
supabase functions new process-order
# crea supabase/functions/process-order/index.ts

supabase functions serve process-order    # probar local
supabase functions deploy process-order   # deploy al proyecto linkeado
```

## Función típica con CORS y validación

```typescript
// supabase/functions/process-order/index.ts
import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',   // restringir a tu dominio en prod
  'Access-Control-Allow-Headers': 'authorization, content-type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    // Cliente con el JWT del usuario que llama → RLS aplica como ese usuario
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } },
    );

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: 'No autenticado' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    const { orderId } = await req.json();
    const { data, error } = await supabase
      .from('orders').select().eq('id', orderId).maybeSingle();
    if (error) throw error;

    return new Response(JSON.stringify({ order: data }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
  }
});
```

## Webhook receptor (sin JWT de usuario)

```typescript
// Para webhooks externos: validar secret propio y desactivar verificación JWT
// supabase/config.toml:
// [functions.payment-webhook]
// verify_jwt = false

Deno.serve(async (req) => {
  if (req.headers.get('x-webhook-secret') !== Deno.env.get('WEBHOOK_SECRET')) {
    return new Response('Unauthorized', { status: 401 });
  }
  // Aquí sí: cliente admin con service_role (estamos en el servidor)
  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );
  const payload = await req.json();
  await admin.from('payment_events').insert({ raw: payload });
  return new Response('ok');   // responder rápido; lo pesado, en otro proceso
});
```

## Secrets

```powershell
supabase secrets set WEBHOOK_SECRET=valor GEMINI_API_KEY=valor
supabase secrets list
```
- `SUPABASE_URL`, `SUPABASE_ANON_KEY` y `SUPABASE_SERVICE_ROLE_KEY` vienen
  inyectadas automáticamente.
- Local: archivo `supabase/functions/.env` (en `.gitignore`).

## Invocación desde clientes

```typescript
// supabase-js (pasa el JWT del usuario automáticamente)
const { data, error } = await supabase.functions.invoke('process-order', {
  body: { orderId },
});
```
```dart
// supabase_flutter
final res = await supabase.functions.invoke('process-order',
    body: {'orderId': orderId});
```

## Reglas

- Una función = una responsabilidad; nombres kebab-case descriptivos
- Responder < 1s a webhooks externos (Meta reintenta ante timeout)
- Log con `console.log` → visible en el dashboard (no loggear secretos)
- Las funciones viven en `supabase/functions/` versionadas en git
