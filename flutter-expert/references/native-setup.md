# Configuración Nativa Android / iOS

## Cámara
AndroidManifest.xml: `<uses-permission android:name="android.permission.CAMERA"/>`
Info.plist: `<key>NSCameraUsageDescription</key><string>Para fotografiar productos</string>`

## Galería (Android 33+)
`<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>`

## Internet HTTP (desarrollo)
`<application android:usesCleartextTraffic="true" ...>`
Quitar en producción — usar HTTPS.

## Versión mínima Android
`android/app/build.gradle`: `minSdkVersion 21`

## Flavors / Entornos
```dart
enum Flavor { dev, staging, prod }
class AppConfig {
  static Flavor flavor = Flavor.dev;
  static String get apiUrl => switch (flavor) {
    Flavor.dev => 'http://10.0.2.2:8000',
    Flavor.staging => 'https://staging.api.com',
    Flavor.prod => 'https://api.com',
  };
}
```
```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter build apk --flavor prod -t lib/main_prod.dart
```
