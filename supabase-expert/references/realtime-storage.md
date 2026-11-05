# Realtime y Storage

## Realtime

### Requisito previo
```sql
-- Habilitar la tabla en la publicación de realtime
alter publication supabase_realtime add table public.orders;
```
RLS aplica también a realtime: el cliente solo recibe cambios de filas que
puede ver por SELECT.

### postgres_changes — reaccionar a cambios de la BD

```typescript
const channel = supabase
  .channel('orders-changes')
  .on('postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'orders',
      filter: 'empresa_id=eq.' + empresaId },
    (payload) => onNewOrder(payload.new),
  )
  .subscribe();

// SIEMPRE limpiar al desmontar
await supabase.removeChannel(channel);
```

### broadcast — mensajes efímeros entre clientes (no tocan la BD)
```typescript
// Cursores, "está escribiendo...", notificaciones volátiles
channel.send({ type: 'broadcast', event: 'typing', payload: { userId } });
channel.on('broadcast', { event: 'typing' }, ({ payload }) => ...);
```

### presence — quién está conectado
```typescript
channel.on('presence', { event: 'sync' }, () => {
  const online = channel.presenceState();
});
await channel.track({ userId, joinedAt: Date.now() });
```

### Reglas realtime
- Un canal por contexto, no por componente — reusar y limpiar en unmount/dispose
- `filter` en el servidor (no filtrar todo el stream en el cliente)
- Para listas que se refrescan solas en Flutter: `.stream(primaryKey: ['id'])`
  (ver flutter-expert/references/supabase-flutter.md)
- Realtime es "best effort": ante reconexión, re-sincronizar con un fetch

---

## Storage

### Buckets — público vs privado

| Tipo | Uso | Acceso |
|---|---|---|
| Público | Imágenes de catálogo, avatares, assets | `getPublicUrl()` — URL permanente |
| Privado | Documentos, facturas, contenido de pago | `createSignedUrl()` — expira |

### Políticas de storage (son RLS sobre `storage.objects`)

```sql
-- Lectura pública del bucket de imágenes
create policy "public read images"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'images');

-- Cada usuario sube solo a su carpeta: avatars/{user_id}/...
create policy "users upload own folder"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
```

### Subida y URLs

```typescript
const path = `products/${crypto.randomUUID()}.jpg`;
const { error } = await supabase.storage
  .from('images')
  .upload(path, file, { contentType: 'image/jpeg', upsert: false });

// Pública
const { data } = supabase.storage.from('images').getPublicUrl(path);

// Privada con expiración (1 hora)
const { data } = await supabase.storage.from('private').createSignedUrl(path, 3600);
```

### Transformación de imágenes (planes Pro+)

```typescript
supabase.storage.from('images').getPublicUrl(path, {
  transform: { width: 400, height: 400, resize: 'cover', quality: 75 },
});
```
Sirve thumbnails sin generar variantes manualmente.

### Reglas storage
- Nombres de archivo generados (uuid/timestamp) — nunca el nombre original
  del usuario (colisiones, caracteres raros, fuga de información)
- Guardar el `path` en la BD, no la URL completa (la URL se deriva)
- Borrar el archivo de storage cuando se borra el registro (o job de limpieza)
- Límite de tamaño en el bucket + validación de `contentType` al subir
