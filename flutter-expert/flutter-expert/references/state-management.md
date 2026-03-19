# Patrones de Gestión de Estado

## §Provider

```dart
// ChangeNotifier
class ProductProvider extends ChangeNotifier {
  List<Product> _items = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetch() async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      _items = await repository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }
}

// Registro en main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ProductProvider()),
    ProxyProvider<AuthProvider, CartProvider>(
      update: (_, auth, __) => CartProvider(auth.userId),
    ),
  ],
  child: MaterialApp(...),
)

// Consumir
Consumer<ProductProvider>(
  builder: (context, p, child) {
    if (p.isLoading) return const CircularProgressIndicator();
    if (p.error != null) return Text('Error: ${p.error}');
    return ListView.builder(itemCount: p.items.length, itemBuilder: (_, i) => Tile(p.items[i]));
  },
)

// Solo acción (no necesita rebuild)
ElevatedButton(
  onPressed: () => context.read<ProductProvider>().fetch(),
  child: const Text('Cargar'),
)

// Escuchar solo un campo específico (menos rebuilds)
final isLoading = context.select<ProductProvider, bool>((p) => p.isLoading);
```

---

## §Riverpod

```dart
// Provider de datos async
@riverpod
Future<List<Product>> products(ProductsRef ref) async {
  return ref.watch(productRepositoryProvider).getAll();
}

// StateNotifier para estado mutable
@riverpod
class CartNotifier extends _$CartNotifier {
  @override
  List<CartItem> build() => [];

  void add(Product p) => state = [...state, CartItem(product: p)];
  void remove(String id) => state = state.where((i) => i.id != id).toList();
}

// ConsumerWidget
class ProductList extends ConsumerWidget {
  const ProductList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    return products.when(
      data: (items) => ListView.builder(itemCount: items.length, itemBuilder: (_, i) => Tile(items[i])),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

// Acción
ref.read(cartNotifierProvider.notifier).add(product);
```

---

## §Bloc

```dart
// Cubit (más simple)
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
}

// Bloc (con eventos)
abstract class ProductEvent {}
class FetchRequested extends ProductEvent {}

abstract class ProductState {}
class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {
  final List<Product> products;
  const ProductLoaded(this.products);
}
class ProductError extends ProductState {
  final String message;
  const ProductError(this.message);
}

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc(this._repo) : super(ProductInitial()) {
    on<FetchRequested>(_onFetch);
  }
  final ProductRepository _repo;

  Future<void> _onFetch(FetchRequested event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      emit(ProductLoaded(await _repo.getAll()));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}

// Widget
BlocBuilder<ProductBloc, ProductState>(
  builder: (context, state) => switch (state) {
    ProductLoading() => const CircularProgressIndicator(),
    ProductLoaded(:final products) => ListView.builder(...),
    ProductError(:final message) => Text(message),
    _ => const SizedBox.shrink(),
  },
)
```

---

## §GetX

```dart
// Controller
class ProductController extends GetxController {
  final products = <Product>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() { super.onInit(); fetch(); }

  Future<void> fetch() async {
    isLoading.value = true;
    try { products.value = await ProductRepository().getAll(); }
    finally { isLoading.value = false; }
  }
}

// Registro
Get.lazyPut(() => ProductController());

// Widget
Obx(() {
  final ctrl = Get.find<ProductController>();
  if (ctrl.isLoading.value) return const CircularProgressIndicator();
  return ListView.builder(itemCount: ctrl.products.length, ...);
})

// Navegación
Get.toNamed('/products');
Get.back();
Get.offAllNamed('/login');
```
