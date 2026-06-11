# Supabase en Flutter — supabase_flutter

## Setup

```dart
// main.dart — antes de runApp
await Supabase.initialize(
  url: AppConfig.supabaseUrl,
  anonKey: AppConfig.supabaseAnonKey,
);

// Acceso global al cliente
final supabase = Supabase.instance.client;
```

**Seguridad:** la `anon key` en el cliente es normal y esperada — la protección
real es RLS en las tablas. La `service_role key` **jamás** va en el app móvil.

---

## Auth

```dart
// Registro / login
final res = await supabase.auth.signUp(email: email, password: password);
final res = await supabase.auth.signInWithPassword(email: email, password: password);

// Sesión actual
final session = supabase.auth.currentSession;   // null si no hay login
final user = supabase.auth.currentUser;

// Escuchar cambios de sesión (login, logout, refresh)
supabase.auth.onAuthStateChange.listen((data) {
  final event = data.event; // signedIn, signedOut, tokenRefreshed
  final session = data.session;
});

// Logout
await supabase.auth.signOut();
```

---

## Queries

```dart
// SELECT con filtros y paginación
final products = await supabase
    .from('products')
    .select('*, category:categories(name)')   // join
    .eq('is_active', true)
    .order('created_at', ascending: false)
    .range(offset, offset + limit - 1);

// SELECT uno (null si no existe — preferir sobre .single())
final product = await supabase
    .from('products')
    .select()
    .eq('id', id)
    .maybeSingle();

// INSERT con retorno
final inserted = await supabase
    .from('products')
    .insert({'name': 'Nike Air', 'price': 150000})
    .select()
    .single();

// UPDATE / DELETE
await supabase.from('products').update({'is_sold_out': true}).eq('id', id);
await supabase.from('products').delete().eq('id', id);
```

---

## Realtime

```dart
// Stream de una tabla (se actualiza solo) — ideal para listas reactivas
final stream = supabase
    .from('orders')
    .stream(primaryKey: ['id'])
    .eq('status', 'pending')
    .order('created_at');

StreamBuilder(
  stream: stream,
  builder: (context, snapshot) { ... },
)

// Canal con eventos específicos (insert/update/delete)
final channel = supabase
    .channel('public:orders')
    .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'orders',
      callback: (payload) => _onNewOrder(payload.newRecord),
    )
    .subscribe();

// SIEMPRE liberar el canal en dispose()
await supabase.removeChannel(channel);
```

---

## Storage

```dart
// Subir imagen
final path = 'products/${DateTime.now().millisecondsSinceEpoch}.jpg';
await supabase.storage.from('images').uploadBinary(
  path,
  bytes,
  fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
);

// URL pública (bucket público)
final url = supabase.storage.from('images').getPublicUrl(path);

// URL firmada (bucket privado, expira)
final signed = await supabase.storage.from('private').createSignedUrl(path, 3600);
```

---

## Manejo de errores

```dart
try {
  await supabase.from('products').insert(data);
} on PostgrestException catch (e) {
  // e.code: '23505' = unique violation, '42501' = RLS denegó la operación
  if (e.code == '42501') throw AppException('Sin permisos para esta operación');
  throw AppException('Error de base de datos: ${e.message}');
} on AuthException catch (e) {
  throw AppException('Error de autenticación: ${e.message}');
} on StorageException catch (e) {
  throw AppException('Error subiendo archivo: ${e.message}');
}
```

**Si una query retorna vacío inesperadamente:** casi siempre es RLS — la
política no permite el SELECT para ese usuario. Revisar políticas antes de
debuggear el código Dart.

---

## Checklist al integrar Supabase en Flutter

- [ ] RLS habilitado en TODAS las tablas que toca el app
- [ ] `anon key` en config por entorno, nunca la `service_role`
- [ ] `maybeSingle()` en vez de `single()` cuando el registro puede no existir
- [ ] Canales realtime liberados en `dispose()`
- [ ] Errores `PostgrestException`/`AuthException` mapeados a mensajes de usuario
