import 'package:chopper/chopper.dart';

part 'cellar_api_service.chopper.dart';

/// Avaliações do usuário autenticado ("Minha adega"). O token é injetado
/// pelo `AuthHeaderInterceptor`.
@ChopperApi(baseUrl: '/v1')
abstract class CellarApiService extends ChopperService {
  static CellarApiService create([ChopperClient? client]) =>
      _$CellarApiService(client);

  /// `{"reviews": [{id, wine_id, nota, comentario, tags, created_at,
  /// wine}], "pagination": {offset, limit, has_more, next_offset}}` (mais
  /// recentes primeiro). 401 sem sessão. Parâmetros `null` não são enviados.
  @GET(path: '/me/reviews')
  Future<Response<dynamic>> getMyReviews({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });
}
