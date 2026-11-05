# Reglas específicas — Dart / Flutter

## 🔴 CRÍTICO

### IP o URLs hardcodeadas
```dart
// ❌
final String apiUrl = 'http://192.168.1.100:8000';

// ✅ Configurable por entorno
class AppConfig {
  static String get apiUrl {
    if (kDebugMode) return 'http://10.0.2.2:8000';
    return 'https://api.tudominio.com';
  }
}
```

### Secrets en el código cliente
```dart
// ❌ API keys en el app móvil (se pueden extraer del APK)
const String geminiApiKey = 'AIzaSy...';

// ✅ Las llamadas a APIs con secrets siempre van por el backend
// El app solo llama a tu propio backend, nunca directamente a Gemini/Supabase con service key
```

### BuildContext en async gaps
```dart
// ❌ Crash si el widget se destruye durante el await
Future<void> _save() async {
  await repository.save(data);
  Navigator.of(context).pop(); // puede crashear
}

// ✅
Future<void> _save() async {
  await repository.save(data);
  if (!mounted) return;
  Navigator.of(context).pop();
}
```

---

## 🟡 MEDIO

### setState para estado global
```dart
// ❌ setState con datos que otros widgets necesitan
class ProductListState extends State<ProductList> {
  List<Product> products = [];
  void loadProducts() async {
    final data = await api.getProducts();
    setState(() => products = data); // solo este widget se actualiza
  }
}

// ✅ Provider para estado compartido
class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<Product> get products => _products;

  Future<void> load() async {
    _products = await api.getProducts();
    notifyListeners();
  }
}
```

### Widgets sin const
```dart
// ❌ Reconstruye innecesariamente
Text('Título')
SizedBox(height: 16)
Icon(Icons.home)

// ✅
const Text('Título')
const SizedBox(height: 16)
const Icon(Icons.home)
```

### Dio instanciado múltiples veces
```dart
// ❌ Nueva instancia en cada llamada
Future<List<Product>> getProducts() async {
  final dio = Dio(); // nueva instancia cada vez
  final response = await dio.get('/products');
  return ...;
}

// ✅ Singleton centralizado
class ApiService {
  static final ApiService instance = ApiService._();
  late final Dio _dio;
  ApiService._() { _dio = Dio(BaseOptions(baseUrl: AppConfig.apiUrl)); }
}
```

---

## 🟢 BAJO

### dispose incompleto
```dart
// ✅ Siempre disponer todos los recursos
@override
void dispose() {
  _controller.dispose();
  _timer?.cancel();
  _subscription?.cancel();
  _focusNode.dispose();
  super.dispose();
}
```

### Nombres poco descriptivos
```dart
// ❌
var d = await api.get('/p');
for (var i in d) { ... }

// ✅
final products = await productService.getAll();
for (final product in products) { ... }
```
