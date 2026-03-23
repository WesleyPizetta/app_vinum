// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wine_api_service.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$WineApiService extends WineApiService {
  _$WineApiService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = WineApiService;

  @override
  Future<Response<dynamic>> getWines() {
    final Uri $url = Uri.parse('/wines');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> getWineById(String id) {
    final Uri $url = Uri.parse('/wines/${id}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<dynamic, dynamic>($request);
  }
}
