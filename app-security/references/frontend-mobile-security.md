# Seguridad frontend y móvil — Next.js y Flutter

## Next.js

### Tabla de detección

| Buscar (Grep) | Si aparece | Severidad |
|---|---|---|
| `NEXT_PUBLIC_.*(SERVICE_ROLE|SECRET|PRIVATE)` en `.env*` o código | Secret en el bundle del navegador | 🔴 |
| `SUPABASE_SERVICE_ROLE_KEY` importado en archivo con `'use client'` | service_role al cliente | 🔴 |
| `dangerouslySetInnerHTML` con datos de usuario/BD sin sanitizar | XSS almacenado | 🔴 |
| `getSession()` decidiendo acceso en middleware/servidor | Sesión falsificable como auth | 🔴 |
| Server action sin verificación de sesión/permiso | Mutación abierta (la URL del action es pública) | 🔴 |
| Sin `headers()` de seguridad en `next.config` | Endurecimiento faltante | 🟢 |

### Fixes clave

```typescript
// 🔴 XSS: sanitizar SIEMPRE que el HTML venga de usuarios/BD
import DOMPurify from 'isomorphic-dompurify';
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />
// JSON-LD con datos propios controlados: aceptable sin sanitizar;
// con datos de usuario: escapar (p. ej. reemplazar `<` por `<`)
```

```typescript
// 🔴 Server Actions también son endpoints públicos — auth adentro SIEMPRE
'use server';
export async function deleteProduct(id: string) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();  // getUser, no getSession
  if (!user) throw new Error('No autenticado');
  // verificación de permiso sobre el recurso, no solo "está logueado"
}
```

```typescript
// 🟢 Security headers — next.config.ts
const securityHeaders = [
  { key: 'X-Frame-Options', value: 'DENY' },                  // clickjacking
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains' },
  // CSP: empezar en Report-Only para no romper estilos/scripts inline
];
export default {
  async headers() { return [{ source: '/(.*)', headers: securityHeaders }]; },
};
```

Checklist extra Next.js:
- [ ] Variables: secrets SIN `NEXT_PUBLIC_`, usados solo en código de servidor
- [ ] Route handlers de webhooks con verificación de firma/secret
- [ ] Redirecciones con allowlist (no `redirect(searchParams.url)` abierto)
- [ ] Validación zod en TODA server action (el cliente no es frontera de confianza)

---

## Flutter

**Premisa:** todo lo que va en el APK/IPA es extraíble (strings, assets,
dart constants). El app NUNCA guarda secretos de servidor.

### Tabla de detección

| Buscar (Grep en `lib/` y config) | Si aparece | Severidad |
|---|---|---|
| `(AIza|sk-|eyJ[A-Za-z0-9_-]{20,})` como literal Dart | API key extraíble del APK | 🔴 |
| `service_role` en cualquier parte del app | Clave admin en el cliente | 🔴 |
| `SharedPreferences` guardando `token|password|jwt` | Almacenamiento legible (root/backup) | 🟡 |
| `usesCleartextTraffic="true"` en AndroidManifest | HTTP plano en producción | 🟡 |
| `badCertificateCallback.*true` o `allowBadCertificates` | Valida cualquier certificado (MITM) | 🔴 |
| `http://` en URLs de producción | Tráfico sin cifrar | 🟡 |

### Fixes clave

```dart
// 🔴 Las API keys de terceros (Gemini, etc.) viven en TU backend:
// el app llama a tu API autenticada y tu backend llama al tercero.
// La anon key de Supabase es la excepción válida (protegida por RLS).

// 🟡 Tokens de sesión: secure storage, no SharedPreferences
// ❌ prefs.setString('jwt', token);
// ✅
const storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);
await storage.write(key: 'jwt', value: token);
// (supabase_flutter ya gestiona su sesión de forma segura — no duplicarla)
```

```xml
<!-- 🟡 cleartext solo para dev, NUNCA en el build de producción -->
<!-- Usar flavors: manifest de debug con cleartext, el de release sin él -->
<application android:usesCleartextTraffic="false" ...>
```

```dart
// 🔴 Nunca deshabilitar la validación TLS "para que funcione"
// ❌ ..badCertificateCallback = (cert, host, port) => true
// Si el backend tiene certificado válido (Let's Encrypt), esto sobra.
// Pinning (apps con datos sensibles): validar el fingerprint esperado
// del certificado en badCertificateCallback, no retornar true.
```

Checklist extra Flutter:
- [ ] Config por entorno (dev/prod) con flavors — la URL de prod no es la IP local
- [ ] `flutter build apk --release` con `--obfuscate --split-debug-info=...`
      (dificulta, no impide, la ingeniería inversa)
- [ ] Logs de release sin tokens ni datos personales (`kReleaseMode` gates)
- [ ] Deep links validados (no navegar a rutas internas con params sin validar)
