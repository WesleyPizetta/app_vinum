// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_api_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$RecommendationApiService extends RecommendationApiService {
  _$RecommendationApiService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = RecommendationApiService;

  @override
  Future<Response<dynamic>> getRecommendations({
    int? limit,
    int? offset,
    String? food,
  }) {
    final Uri $url = Uri.parse('/v1/me/recommendations');
    final Map<String, dynamic> $params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'food': food,
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
  Future<Response<dynamic>> getWineMatch(String wineId) {
    final Uri $url = Uri.parse('/v1/me/wines/${wineId}/match');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> search({
    required String query,
    int? limit,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/v1/me/search');
    final Map<String, dynamic> $params = <String, dynamic>{
      'q': query,
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
}
