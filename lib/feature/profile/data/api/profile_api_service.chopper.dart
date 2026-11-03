// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_api_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$ProfileApiService extends ProfileApiService {
  _$ProfileApiService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = ProfileApiService;

  @override
  Future<Response<dynamic>> getMyProfile({
    required String authorization,
  }) {
    final Uri $url = Uri.parse('/v1/me/profile');
    final Map<String, String> $headers = {
      'Authorization': authorization,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      headers: $headers,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getOnboardingQuiz() {
    final Uri $url = Uri.parse('/v1/onboarding/quiz');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> submitOnboardingQuiz(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/v1/onboarding/quiz/submit');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> checkNickname(String nickname) {
    final Uri $url = Uri.parse('/v1/nicknames/check');
    final Map<String, dynamic> $params = <String, dynamic>{
      'nickname': nickname,
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
  Future<Response<dynamic>> setMyNickname(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/v1/me/nickname');
    final $body = body;
    final Request $request = Request(
      'PUT',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
