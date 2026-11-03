import 'package:chopper/chopper.dart';

part 'favorite_api_service.chopper.dart';

/// Favoritos do usuário autenticado. O token é injetado pelo
/// `AuthHeaderInterceptor`.
@ChopperApi(baseUrl: '/v1')
abstract class FavoriteApiService extends ChopperService {
  static FavoriteApiService create([ChopperClient? client]) =>
      _$FavoriteApiService(client);

  /// `{"wine_ids": [100003, 108705]}`
  @GET(path: '/me/favorites/ids')
  Future<Response<dynamic>> getFavoriteIds();

  /// `{"favorites": [...], "pagination": {...}}` (mais recentes primeiro).
  /// Parâmetros `null` não são enviados.
  @GET(path: '/me/favorites')
  Future<Response<dynamic>> getFavorites({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  /// Idempotente. `{"wine_id": 100003, "is_favorite": true}`; 404 se o vinho
  /// não existe.
  @PUT(path: '/me/favorites/{wine_id}')
  Future<Response<dynamic>> addFavorite(@Path('wine_id') String wineId);

  /// Idempotente. `{"wine_id": 100003, "is_favorite": false}`.
  @DELETE(path: '/me/favorites/{wine_id}')
  Future<Response<dynamic>> removeFavorite(@Path('wine_id') String wineId);
}
