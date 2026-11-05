# Provider — Patrones y Convenciones

## Setup en main.dart

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        // ProxyProvider cuando un provider depende de otro
        ProxyProvider<AuthProvider, ApiService>(
          update: (_, auth, __) => ApiService(token: auth.token),
        ),
        ChangeNotifierProxyProvider<ApiService, CatalogProvider>(
          create: (_) => CatalogProvider(),
          update: (_, api, catalog) => catalog!..updateApi(api),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

## ChangeNotifier — patrón estándar

```dart
class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  // Getters — siempre privado + getter público
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts(String slug) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await ApiService.instance.getProducts(slug);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

## Consumer — rebuild granular

```dart
// ✅ Consumer solo donde se necesita el estado
Scaffold(
  appBar: AppBar(title: const Text('Productos')),  // no necesita rebuild
  body: Consumer<ProductProvider>(
    builder: (context, provider, child) {
      if (provider.isLoading) return const CircularProgressIndicator();
      if (provider.error != null) return ErrorWidget(provider.error!);
      return ProductList(products: provider.products);
    },
  ),
)

// ✅ child para widgets que no dependen del estado (evita rebuild)
Consumer<ProductProvider>(
  builder: (context, provider, child) {
    return Column(children: [
      Text('${provider.products.length} productos'),
      child!,  // no se reconstruye
    ]);
  },
  child: const ExpensiveStaticWidget(),
)
```

## Selector — rebuild ultra-granular

```dart
// Solo se reconstruye si cambia isLoading, no ante cualquier notifyListeners
Selector<ProductProvider, bool>(
  selector: (_, provider) => provider.isLoading,
  builder: (_, isLoading, __) {
    return isLoading
        ? const CircularProgressIndicator()
        : const SizedBox.shrink();
  },
)
```

## Provider.of — para acciones sin rebuild

```dart
// ✅ listen: false para acciones (onPressed, etc.)
ElevatedButton(
  onPressed: () {
    Provider.of<ProductProvider>(context, listen: false).fetchProducts(slug);
  },
  child: const Text('Cargar'),
)

// ✅ context.read — shorthand de Flutter (requiere import provider)
ElevatedButton(
  onPressed: () => context.read<ProductProvider>().fetchProducts(slug),
  child: const Text('Cargar'),
)

// ✅ context.watch — equivale a Consumer (causa rebuild)
final count = context.watch<ProductProvider>().products.length;
```

## Errores comunes con Provider

```
ProviderNotFoundException
→ El provider no está registrado en el árbol por encima del widget que lo usa
→ Verificar que MultiProvider está por encima de MaterialApp

Error: Called notifyListeners() after dispose()
→ El provider fue disposed pero un Future completó después
→ Agregar: if (!_disposed) notifyListeners()
→ Y en dispose(): _disposed = true; super.dispose();
```
