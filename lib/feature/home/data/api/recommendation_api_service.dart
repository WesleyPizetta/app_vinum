import 'package:chopper/chopper.dart';

part 'recommendation_api_service.chopper.dart';

@ChopperApi(baseUrl: '/v1')
abstract class RecommendationApiService extends ChopperService {
  static RecommendationApiService create([ChopperClient? client]) =>
      _$RecommendationApiService(client);

  /// Recomendações personalizadas do usuário autenticado.
  /// O token é injetado pelo `AuthHeaderInterceptor`.
  ///
  /// - [offset]: paginação (a resposta traz `pagination.next_offset`).
  /// - [food]: categoria de comida (`meat`, `poultry`, `pork`, `seafood`,
  ///   `pasta`, `cheese`, `vegetarian`, `appetizer`, `dessert`). Sem `food`
  ///   é a recomendação geral da home. Parâmetros `null` não são enviados.
  @GET(path: '/me/recommendations')
  Future<Response<dynamic>> getRecommendations({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('food') String? food,
  });

  /// Afinidade de um vinho com o perfil do usuário e os motivos
  /// ("por que este vinho combina com você").
  ///
  /// Erros: 409 `ONBOARDING_REQUIRED` (sem quiz), 404 (vinho não existe).
  @GET(path: '/me/wines/{wineId}/match')
  Future<Response<dynamic>> getWineMatch(@Path('wineId') String wineId);

  /// Busca por texto (nome, vinícola, região, país, uvas, tipo e pratos em
  /// português). Itens no mesmo formato das recomendações + `foods`
  /// reconhecidas + `pagination`.
  ///
  /// Erros: 400 (`q` com menos de 2 letras), 409 `ONBOARDING_REQUIRED`.
  @GET(path: '/me/search')
  Future<Response<dynamic>> search({
    @Query('q') required String query,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });
}
