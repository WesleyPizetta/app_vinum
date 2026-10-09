// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_api_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$FavoriteApiService extends FavoriteApiService {
  _$FavoriteApiService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = FavoriteApiService;

  @override
  Future<Response<dynamic>> getFavoriteIds() {
    final Uri $url = Uri.parse('/v1/me/favorites/ids');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getFavorites({
    int? limit,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/v1/me/favorites');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> addFavorite(String wineId) {
    final Uri $url = Uri.parse('/v1/me/favorites/${wineId}');
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> removeFavorite(String wineId) {
    final Uri $url = Uri.parse('/v1/me/favorites/${wineId}');
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
