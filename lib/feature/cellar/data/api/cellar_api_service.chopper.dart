// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cellar_api_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$CellarApiService extends CellarApiService {
  _$CellarApiService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = CellarApiService;

  @override
  Future<Response<dynamic>> getMyReviews({
    int? limit,
    int? offset,
  }) {
    final Uri $url = Uri.parse('/v1/me/reviews');
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
}
