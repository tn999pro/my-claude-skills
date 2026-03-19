# GetX — Patrones y Convenciones

## Setup

```dart
// main.dart — reemplazar MaterialApp por GetMaterialApp
void main() {
  runApp(GetMaterialApp(
    initialRoute: '/home',
    getPages: AppPages.routes,
    home: const HomeScreen(),
  ));
}
```

## GetxController — equivalente a ChangeNotifier

```dart
class ProductoController extends GetxController {
  // Variables reactivas con .obs
  final productos = <Producto>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProductos();  // auto-cargar al crear
  }

  Future<void> fetchProductos() async {
    isLoading.value = true;
    error.value = '';
    try {
      productos.value = await ApiService.to.getProductos();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
```

## Registro — Bindings

```dart
// Binding para una pantalla
class ProductoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductoController>(() => ProductoController());
  }
}

// En las rutas
GetPage(
  name: '/productos',
  page: () => const ProductosScreen(),
  binding: ProductoBinding(),
)
```

## Obx — widget reactivo

```dart
class ProductosScreen extends StatelessWidget {
  const ProductosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductoController>();

    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) return const CircularProgressIndicator();
        if (controller.error.value.isNotEmpty) return Text(controller.error.value);
        return ListView.builder(
          itemCount: controller.productos.length,
          itemBuilder: (_, i) => ProductoTile(producto: controller.productos[i]),
        );
      }),
    );
  }
}
```

## Navegación GetX

```dart
// Navegar
Get.toNamed('/productos');
Get.offAllNamed('/login');  // limpiar stack
Get.back();

// Con argumentos
Get.toNamed('/detalle', arguments: {'id': producto.id});
// Recibir
final id = Get.arguments['id'];

// Con parámetros en ruta
Get.toNamed('/producto/123');
// En la ruta: /producto/:id
// Recibir: Get.parameters['id']
```

## GetxService — para singletons persistentes

```dart
// Para servicios que deben vivir toda la app (ApiService, AuthService)
class ApiService extends GetxService {
  static ApiService get to => Get.find();

  late final Dio _dio;

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
  }
}

// Registrar en main.dart antes de runApp
await Get.putAsync(() async {
  final service = ApiService();
  return service;
});
```

## Errores comunes con GetX

```
GetxController not found
→ Binding no registrado o Get.lazyPut vs Get.put
→ Usar Get.put() para instanciación inmediata, Get.lazyPut() para diferida

Widget no actualiza con Obx
→ La variable no es .obs o se reemplazó el objeto completo
→ Usar .value para tipos primitivos, .assignAll() para listas
```
