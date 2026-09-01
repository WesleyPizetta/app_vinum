import 'dart:async';

import 'package:chopper/chopper.dart';

/// Interceptor do Chopper que injeta automaticamente o cabeçalho
/// `Authorization: Bearer <token>` em todas as requisições autenticadas.
class AuthHeaderInterceptor implements Interceptor {
  final String? Function() _tokenProvider;

  const AuthHeaderInterceptor(this._tokenProvider);

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    var request = chain.request;

    if (!request.headers.containsKey('Authorization')) {
      final token = _tokenProvider();
      if (token != null && token.trim().isNotEmpty) {
        final normalized = token.trim();
        final headerValue = normalized.toLowerCase().startsWith('bearer ')
            ? normalized
            : 'Bearer $normalized';

        request = applyHeader(request, 'Authorization', headerValue);
      }
    }

    return chain.proceed(request);
  }
}
