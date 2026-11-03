import 'dart:convert';

import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
// `http` já vem com o chopper (dependência transitiva); só a
// `http.Response` base é necessária para montar a resposta Chopper.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/cellar/data/api/cellar_api_service.dart';
import 'package:vinum/feature/cellar/data/repository/cellar_repository_impl.dart';
import 'package:vinum/feature/cellar/domain/entity/cellar_failure_code.dart';

class MockCellarApiService extends Mock implements CellarApiService {}

/// Resposta Chopper como o `JsonConverter` entrega: `body` decodificado só
/// em 2xx; em erro, o corpo decodificado vai para `error`.
Response<dynamic> _response(int status, [Object? body]) {
  final successful = status >= 200 && status < 300;
  return Response<dynamic>(
    http.Response(body == null ? '' : jsonEncode(body), status),
    successful ? body : null,
    error: successful ? null : body,
  );
}

String? _failureCode(Try<Object?> result) =>
    result.fold((failure) => failure.code, (_) => null);

void main() {
  late MockCellarApiService api;
  late CellarRepositoryImpl repository;

  setUp(() {
    api = MockCellarApiService();
    repository = CellarRepositoryImpl(api);
  });

  void stubAny(Response<dynamic> response) {
    when(() => api.getMyReviews(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async => response);
  }

  test('faz o parse da página e envia limit/offset', () async {
    final response = _response(200, {
      'reviews': [
        {
          'id': 'r1',
          'wine_id': 12,
          'nota': 8.5,
          'tags': ['frutado'],
          'created_at': '2026-09-30T12:00:00Z',
          'wine': {'wine_id': 12, 'name': 'Malbec'},
        },
      ],
      'pagination': {
        'offset': 20,
        'limit': 20,
        'has_more': false,
        'next_offset': null,
      },
    });
    when(() => api.getMyReviews(limit: 20, offset: 20))
        .thenAnswer((_) async => response);

    final result = await repository.getMyReviews(limit: 20, offset: 20);
    final page = result.getOrElse(() => throw StateError('falhou'));

    expect(page.items.single.id, 'r1');
    expect(page.items.single.wine?.name, 'Malbec');
    expect(page.offset, 20);
    expect(page.hasMore, isFalse);
  });

  test('401 -> unauthorized', () async {
    stubAny(_response(401, {'error': 'unauthorized'}));
    final result = await repository.getMyReviews();
    expect(_failureCode(result), CellarFailureCode.unauthorized);
  });

  test('5xx -> server', () async {
    stubAny(_response(503));
    final result = await repository.getMyReviews();
    expect(_failureCode(result), CellarFailureCode.server);
  });

  test('corpo fora do contrato -> invalidResponse', () async {
    stubAny(_response(200, {'items': []}));
    final result = await repository.getMyReviews();
    expect(_failureCode(result), CellarFailureCode.invalidResponse);
  });

  test('exceção na chamada -> UnknownFailure', () async {
    when(() => api.getMyReviews(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenThrow(Exception('offline'));
    final result = await repository.getMyReviews();
    expect(
      result.fold((failure) => failure, (_) => null),
      isA<UnknownFailure>(),
    );
  });
}
