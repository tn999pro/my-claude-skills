# Patrones HTTP en Flutter

## §Dio — Singleton con interceptores

```dart
class ApiClient {
  static final ApiClient instance = ApiClient._();
  late final Dio _dio;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));
    _dio.interceptors.addAll([_AuthInterceptor(), _ErrorInterceptor()]);
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? params}) async {
    final r = await _dio.get(path, queryParameters: params);
    return r.data as T;
  }

  Future<T> post<T>(String path, {dynamic data}) async {
    final r = await _dio.post(path, data: data);
    return r.data as T;
  }

  Future<T> upload<T>(String path, FormData form) async {
    final r = await _dio.post(path, data: form,
      options: Options(contentType: 'multipart/form-data'));
    return r.data as T;
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = SecureStorage.getToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        await AuthService.refresh();
        final response = await ApiClient.instance._dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (_) { AuthService.logout(); }
    }
    handler.next(err);
  }
}
```

## Manejo de errores

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout => const ApiException('Tiempo agotado'),
    DioExceptionType.connectionError => const ApiException('Sin conexión'),
    DioExceptionType.badResponse => ApiException(
        e.response?.data?['message'] ?? 'Error del servidor',
        statusCode: e.response?.statusCode),
    _ => ApiException('Error: ${e.message}'),
  };
}

// En el repository
Future<List<Product>> getProducts() async {
  try {
    final data = await ApiClient.instance.get<List>('/products');
    return data.map((e) => Product.fromJson(e)).toList();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}
```

## Upload de imágenes

```dart
Future<String> uploadImage(File file) async {
  final form = FormData.fromMap({
    'image': await MultipartFile.fromFile(
      file.path,
      filename: 'img_${DateTime.now().millisecondsSinceEpoch}.jpg',
      contentType: DioMediaType('image', 'jpeg'),
    ),
  });
  final response = await ApiClient.instance.upload<Map>('/upload', form);
  return response['url'] as String;
}
```

## §Http package — cliente centralizado

```dart
class HttpClient {
  static final HttpClient instance = HttpClient._();
  final http.Client _client = http.Client();
  HttpClient._();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (AuthService.token != null) 'Authorization': 'Bearer ${AuthService.token}',
  };

  Future<dynamic> get(String path) async {
    final r = await _client.get(Uri.parse('${AppConfig.apiUrl}$path'), headers: _headers);
    return _handle(r);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final r = await _client.post(Uri.parse('${AppConfig.apiUrl}$path'),
      headers: _headers, body: jsonEncode(body));
    return _handle(r);
  }

  dynamic _handle(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return jsonDecode(r.body);
    throw ApiException('Error ${r.statusCode}', statusCode: r.statusCode);
  }
}
```
