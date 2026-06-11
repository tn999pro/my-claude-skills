# Errores Frecuentes de Flutter — Soluciones Rápidas

## BuildContext en gaps async
```dart
Future<void> _submit() async {
  await apiCall();
  if (!context.mounted) return;  // Flutter 3.7+ StatelessWidget
  // if (!mounted) return;       // State<T>
  Navigator.of(context).pop();
}
```

## setState after dispose
```dart
@override
void dispose() {
  _timer?.cancel();
  _controller.dispose();
  super.dispose();
}
if (mounted) setState(() { ... }); // en callbacks async
```

## ProviderNotFoundException
→ MultiProvider no está por encima del widget que lo usa
→ Verificar que MultiProvider envuelve MaterialApp

## Gradle build failed
```bash
flutter clean && flutter pub get
cd android && ./gradlew clean && cd ..
flutter build apk
```

## FVM no reconocido en PowerShell
```powershell
dart pub global activate fvm
# Agregar al PATH: %APPDATA%\Pub\Cache\bin
fvm install
```

## DioException / Connection refused
- Emulador Android → usar 10.0.2.2 en vez de localhost
- Dispositivo físico → IP local (ipconfig en Windows)
- Verificar que el backend esté corriendo

## build_runner conflictos
```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

## Permisos cámara
```xml
<!-- Android: AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA"/>
<!-- iOS: Info.plist -->
<key>NSCameraUsageDescription</key><string>Acceso a cámara</string>
```

## RenderFlex overflowed
```dart
Column(children: [
  const Header(),
  Expanded(child: ListView.builder(...)),
])
```

## Image.network no carga
```dart
Image.network(url,
  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
  loadingBuilder: (_, child, p) => p == null ? child : const CircularProgressIndicator(),
)
```
