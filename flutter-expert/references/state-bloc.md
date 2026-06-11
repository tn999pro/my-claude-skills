# Bloc / Cubit — Patrones y Convenciones

## Cubit — cuando la lógica es simple

```dart
// Estado
@freezed
class ProductoState with _$ProductoState {
  const factory ProductoState.initial() = _Initial;
  const factory ProductoState.loading() = _Loading;
  const factory ProductoState.loaded(List<Producto> productos) = _Loaded;
  const factory ProductoState.error(String mensaje) = _Error;
}

// Cubit
class ProductoCubit extends Cubit<ProductoState> {
  ProductoCubit(this._repo) : super(const ProductoState.initial());

  final ProductoRepository _repo;

  Future<void> cargar(String slug) async {
    emit(const ProductoState.loading());
    try {
      final productos = await _repo.getProductos(slug);
      emit(ProductoState.loaded(productos));
    } catch (e) {
      emit(ProductoState.error(e.toString()));
    }
  }
}
```

## Bloc — cuando hay múltiples eventos

```dart
// Eventos
abstract class ProductoEvent {}
class ProductoFetchRequested extends ProductoEvent {
  const ProductoFetchRequested(this.slug);
  final String slug;
}
class ProductoRefreshRequested extends ProductoEvent {}

// Bloc
class ProductoBloc extends Bloc<ProductoEvent, ProductoState> {
  ProductoBloc(this._repo) : super(const ProductoState.initial()) {
    on<ProductoFetchRequested>(_onFetch);
    on<ProductoRefreshRequested>(_onRefresh);
  }

  final ProductoRepository _repo;

  Future<void> _onFetch(ProductoFetchRequested event, Emitter<ProductoState> emit) async {
    emit(const ProductoState.loading());
    try {
      final productos = await _repo.getProductos(event.slug);
      emit(ProductoState.loaded(productos));
    } catch (e) {
      emit(ProductoState.error(e.toString()));
    }
  }

  Future<void> _onRefresh(ProductoRefreshRequested event, Emitter<ProductoState> emit) async {
    // lógica de refresh
  }
}
```

## Registro de providers

```dart
// Un bloc
BlocProvider(
  create: (context) => ProductoBloc(context.read<ProductoRepository>()),
  child: ProductosScreen(),
)

// Múltiples blocs
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => AuthBloc()),
    BlocProvider(create: (_) => ProductoBloc(repo)),
  ],
  child: const MyApp(),
)
```

## BlocBuilder, BlocListener, BlocConsumer

```dart
// BlocBuilder — solo rebuild de UI
BlocBuilder<ProductoCubit, ProductoState>(
  builder: (context, state) {
    return state.when(
      initial: () => const SizedBox(),
      loading: () => const CircularProgressIndicator(),
      loaded: (productos) => ProductoList(productos: productos),
      error: (msg) => Text('Error: $msg'),
    );
  },
)

// BlocListener — solo efectos secundarios (sin rebuild)
BlocListener<ProductoCubit, ProductoState>(
  listener: (context, state) {
    state.whenOrNull(
      error: (msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      ),
    );
  },
  child: const Body(),
)

// BlocConsumer — ambos
BlocConsumer<ProductoCubit, ProductoState>(
  listener: (context, state) { /* efectos */ },
  builder: (context, state) { /* UI */ },
)
```

## Disparar eventos / llamar métodos

```dart
// Desde onPressed (sin rebuild)
context.read<ProductoCubit>().cargar(slug);
context.read<ProductoBloc>().add(ProductoFetchRequested(slug));
```
