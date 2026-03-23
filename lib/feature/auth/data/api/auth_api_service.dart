import 'package:chopper/chopper.dart';

part 'auth_api_service.chopper.dart';

/// Serviço Chopper para os endpoints de autenticação do BFF.
///
/// Gere o código com:
/// ```bash
/// dart run build_runner build --delete-conflicting-outputs
/// ```
@ChopperApi(baseUrl: '/v1/auth')
abstract class AuthApiService extends ChopperService {
  static AuthApiService create([ChopperClient? client]) =>
      _$AuthApiService(client);

  @POST(path: '/social/exchange')
  Future<Response<dynamic>> socialExchange(@Body() Map<String, dynamic> body);

  @POST(path: '/refresh')
  Future<Response<dynamic>> refresh(@Body() Map<String, dynamic> body);

  @POST(path: '/logout')
  Future<Response<dynamic>> logout(
    @Body() Map<String, dynamic> body, {
    @Header('Authorization') String? authorization,
  });
}
