import 'package:chopper/chopper.dart';

part 'wine_api_service.chopper.dart';

/// Serviço Chopper para a API de vinhos.
///
/// Gera automaticamente o client HTTP com `build_runner`:
/// ```bash
/// dart run build_runner build --delete-conflicting-outputs
/// ```
// TODO: Ajustar os endpoints quando a API real estiver disponível
@ChopperApi(baseUrl: '/v1/wines')
abstract class WineApiService extends ChopperService {
  static WineApiService create([ChopperClient? client]) =>
      _$WineApiService(client);

  @GET()
  Future<Response<dynamic>> getWines();

  @GET(path: '/{id}')
  Future<Response<dynamic>> getWineById(@Path('id') String id);
}
