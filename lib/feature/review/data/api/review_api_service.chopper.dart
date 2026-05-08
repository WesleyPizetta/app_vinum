// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_api_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$ReviewApiService extends ReviewApiService {
  _$ReviewApiService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = ReviewApiService;

  @override
  Future<Response<dynamic>> getWineReviews(String wineId) {
    final Uri $url = Uri.parse('/v1/wines/$wineId/reviews');
    final Request $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> createReview(
    String wineId,
    Map<String, dynamic> body, {
    String? authorization,
  }) {
    final Uri $url = Uri.parse('/v1/wines/$wineId/reviews');
    final Map<String, String> $headers = {
      if (authorization != null) 'Authorization': authorization,
    };
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> updateReview(
    String id,
    Map<String, dynamic> body, {
    String? authorization,
  }) {
    final Uri $url = Uri.parse('/v1/reviews/$id');
    final Map<String, String> $headers = {
      if (authorization != null) 'Authorization': authorization,
    };
    final $body = body;
    final Request $request = Request(
      'PATCH',
      $url,
      client.baseUrl,
      body: $body,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> deleteReview(
    String id, {
    String? authorization,
  }) {
    final Uri $url = Uri.parse('/v1/reviews/$id');
    final Map<String, String> $headers = {
      if (authorization != null) 'Authorization': authorization,
    };
    final Request $request = Request(
      'DELETE',
      $url,
      client.baseUrl,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
