# Performance en Flutter

## Evitar rebuilds innecesarios
```dart
// context.select — rebuild solo si cambia ese campo específico
final title = context.select<ProductProvider, String>((p) => p.title);

// Consumer solo donde se necesita el estado
body: Consumer<ProductProvider>(
  builder: (_, p, __) => ProductList(items: p.items),
)
// No en: AppBar, botones fijos, elementos que no dependen del estado
```

## Isolates para trabajo pesado
```dart
// compute() — para operaciones costosas (compresión, parsing JSON grande)
final result = await compute(_procesarImagen, imageBytes);

// Función top-level (requerido por compute)
Uint8List _procesarImagen(Uint8List bytes) { /* heavy work */ return result; }
```

## ListView eficiente
```dart
ListView.builder(
  itemCount: items.length,
  itemExtent: 80.0, // mejora rendimiento si todos tienen el mismo alto
  itemBuilder: (_, i) => ProductTile(key: ValueKey(items[i].id), product: items[i]),
)
```

## Imágenes
```dart
// cached_network_image para imágenes remotas
CachedNetworkImage(
  imageUrl: url,
  memCacheWidth: 300,
  placeholder: (_, __) => const Skeleton(),
  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
)

// Precaché para pantallas de detalle
precacheImage(NetworkImage(product.imageUrl), context);
```

## RepaintBoundary para animaciones
```dart
RepaintBoundary(child: AnimatedWidget(...)) // aisla rebuilds del resto del árbol
```
