import 'package:chopper/chopper.dart';

import 'curl_logging_interceptor.dart';

/// Cria um [ChopperClient] pré-configurado com logging de cURL e suporte a JSON.
///
/// ```dart
/// final client = createChopperClient(
///   baseUrl: 'https://api.example.com/v1',
///   services: [WineApiService.create()],
/// );
/// ```
ChopperClient createChopperClient({
  required String baseUrl,
  List<ChopperService> services = const [],
  List<Interceptor> interceptors = const [],
  bool enableCurlLogging = true,
}) {
  return ChopperClient(
    baseUrl: Uri.parse(baseUrl),
    services: services,
    interceptors: [
      if (enableCurlLogging) const CurlLoggingInterceptor(),
      ...interceptors,
    ],
    converter: const JsonConverter(),
    errorConverter: const JsonConverter(),
  );
}
