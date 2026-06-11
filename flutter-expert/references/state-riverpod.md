# Riverpod — Patrones y Convenciones

## Setup

```dart
// main.dart
void main() {
  runApp(const ProviderScope(child: MyApp()));
}

// MyApp usa ConsumerWidget o MaterialApp normal
```

## Tipos de providers más usados

```dart
// Estado simple inmutable
final contadorProvider = StateProvider<int>((ref) => 0);

// Estado con lógica (reemplaza ChangeNotifier)
final productosProvider = StateNotifierProvider<ProductosNotifier, ProductosState>(
  (ref) => ProductosNotifier(ref),
);

// Future (llamadas async, se integra con AsyncValue)
final catalogoProvider = FutureProvider.family<Catalogo, String>((ref, slug) async {
  final api = ref.read(apiServiceProvider);
  return api.getCatalogo(slug);
});

// Stream
final stockProvider = StreamProvider<List<Producto>>((ref) {
  return ref.read(apiServiceProvider).stockStream();
});

// Dependencia entre providers
final apiServiceProvider = Provider<ApiService>((ref) {
  final auth = ref.watch(authProvider);
  return ApiService(token: auth.token);
});
```

## StateNotifier — equivalente a ChangeNotifier

```dart
// Estado inmutable (idealmente con freezed)
@freezed
class ProductosState with _$ProductosState {
  const factory ProductosState({
    @Default([]) List<Producto> productos,
    @Default(false) bool isLoading,
    String? error,
  }) = _ProductosState;
}

class ProductosNotifier extends StateNotifier<ProductosState> {
  ProductosNotifier(this._ref) : super(const ProductosState());

  final Ref _ref;

  Future<void> fetch(String slug) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final productos = await _ref.read(apiServiceProvider).getProductos(slug);
      state = state.copyWith(productos: productos, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
```

## ConsumerWidget — widget que lee providers

```dart
class ProductosScreen extends ConsumerWidget {
  const ProductosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productosProvider);

    if (state.isLoading) return const CircularProgressIndicator();
    if (state.error != null) return Text(state.error!);

    return ListView.builder(
      itemCount: state.productos.length,
      itemBuilder: (_, i) => ProductoTile(producto: state.productos[i]),
    );
  }
}
```

## AsyncValue — para FutureProvider/StreamProvider

```dart
class CatalogoScreen extends ConsumerWidget {
  const CatalogoScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogo = ref.watch(catalogoProvider(slug));

    return catalogo.when(
      data: (data) => CatalogoView(catalogo: data),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

## ref.read vs ref.watch vs ref.listen

```dart
// ref.watch → rebuild cuando cambia (usar en build())
final estado = ref.watch(productosProvider);

// ref.read → sin rebuild (usar en callbacks/onPressed)
ref.read(productosProvider.notifier).fetch(slug);

// ref.listen → efecto secundario cuando cambia (navegar, mostrar snackbar)
ref.listen<ProductosState>(productosProvider, (prev, next) {
  if (next.error != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!)));
  }
});
```

## Invalidar y refrescar

```dart
// Forzar re-fetch de un FutureProvider
ref.invalidate(catalogoProvider(slug));

// Refrescar desde el widget
ref.refresh(catalogoProvider(slug));
```
