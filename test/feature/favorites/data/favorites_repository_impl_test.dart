import 'dart:async';
import 'dart:convert';

import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
// `http` já vem com o chopper (dependência transitiva); só a
// `http.Response` base é necessária para montar a resposta Chopper.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/favorites/data/api/favorite_api_service.dart';
import 'package:vinum/feature/favorites/data/repository/favorites_repository_impl.dart';
import 'package:vinum/feature/favorites/domain/entity/favorite_failure_code.dart';
import 'package:vinum/feature/favorites/domain/entity/favorite_ids.dart';

class MockFavoriteApiService extends Mock implements FavoriteApiService {}

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
  late MockFavoriteApiService api;
  late FavoritesRepositoryImpl repository;
  late List<FavoriteIds> emitted;
  late StreamSubscription<FavoriteIds> subscription;

  setUpAll(() => registerFallbackValue(''));

  setUp(() {
    api = MockFavoriteApiService();
    repository = FavoritesRepositoryImpl(api);
    emitted = [];
    subscription = repository.watchFavoriteIds().listen(emitted.add);
  });

  tearDown(() => subscription.cancel());

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  Future<void> loadWith(List<Object> ids) async {
    final response = _response(200, {'wine_ids': ids});
    when(() => api.getFavoriteIds()).thenAnswer((_) async => response);
    await repository.loadIds();
    await flush();
    emitted.clear();
  }

  group('loadIds', () {
    test('carrega os ids, marca como carregado e emite', () async {
      final response = _response(200, {
        'wine_ids': [100003, 108705],
      });
      when(() => api.getFavoriteIds()).thenAnswer((_) async => response);

      expect(repository.currentFavoriteIds.isLoaded, isFalse);
      final result = await repository.loadIds();
      await flush();

      expect(result.isRight(), isTrue);
      final current = repository.currentFavoriteIds;
      expect(current.isLoaded, isTrue);
      expect(current.ids, {'100003', '108705'});
      expect(current.isFavorite('100003'), isTrue);
      expect(current.isFavorite('1'), isFalse);
      expect(emitted.single.ids, {'100003', '108705'});
    });

    test('chamadas simultâneas compartilham a requisição', () async {
      final response = _response(200, {'wine_ids': [1]});
      when(() => api.getFavoriteIds()).thenAnswer((_) async => response);

      await Future.wait([repository.loadIds(), repository.loadIds()]);
      verify(() => api.getFavoriteIds()).called(1);
    });

    test('401 -> falha unauthorized e cache continua não carregado', () async {
      final response = _response(401, {'error': 'invalid token'});
      when(() => api.getFavoriteIds()).thenAnswer((_) async => response);

      final result = await repository.loadIds();

      expect(_failureCode(result), FavoriteFailureCode.unauthorized);
      expect(repository.currentFavoriteIds.isLoaded, isFalse);
    });

    test('corpo fora do contrato -> invalidResponse', () async {
      final response = _response(200, {'ids': []});
      when(() => api.getFavoriteIds()).thenAnswer((_) async => response);

      final result = await repository.loadIds();
      expect(_failureCode(result), FavoriteFailureCode.invalidResponse);
    });

    test('reaplica operações em voo sobre a resposta', () async {
      final put = Completer<Response<dynamic>>();
      when(() => api.addFavorite('9')).thenAnswer((_) => put.future);
      final idsResponse = _response(200, {'wine_ids': [1]});
      when(() => api.getFavoriteIds()).thenAnswer((_) async => idsResponse);

      final pending = repository.setFavorite('9', true);
      await repository.loadIds();

      expect(repository.currentFavoriteIds.ids, {'1', '9'});

      put.complete(_response(200, {'wine_id': 9, 'is_favorite': true}));
      await pending;
      expect(repository.currentFavoriteIds.ids, {'1', '9'});
    });
  });

  group('setFavorite', () {
    test('atualização otimista antes da resposta e confirmação', () async {
      await loadWith([5]);
      final put = Completer<Response<dynamic>>();
      when(() => api.addFavorite('1')).thenAnswer((_) => put.future);

      final future = repository.setFavorite('1', true);
      await flush();

      // Otimista: já favorito antes da API responder.
      expect(repository.currentFavoriteIds.isFavorite('1'), isTrue);
      expect(emitted.single.ids, {'5', '1'});

      put.complete(_response(200, {'wine_id': 1, 'is_favorite': true}));
      final result = await future;
      await flush();

      expect(result.getOrElse(() => false), isTrue);
      expect(repository.currentFavoriteIds.ids, {'5', '1'});
      expect(emitted, hasLength(1)); // confirmação igual não reemite
    });

    test('falha no PUT -> rollback e emite o set revertido', () async {
      await loadWith([5]);
      final put = Completer<Response<dynamic>>();
      when(() => api.addFavorite('1')).thenAnswer((_) => put.future);

      final future = repository.setFavorite('1', true);
      await flush();
      put.complete(_response(500, {'error': 'boom'}));
      final result = await future;
      await flush();

      expect(_failureCode(result), FavoriteFailureCode.server);
      expect(repository.currentFavoriteIds.ids, {'5'});
      expect(repository.currentFavoriteIds.isFavorite('1'), isFalse);
      expect(emitted.map((e) => e.ids).toList(), [
        {'5', '1'},
        {'5'},
      ]);
    });

    test('exceção no DELETE -> UnknownFailure e rollback', () async {
      await loadWith([1]);
      when(() => api.removeFavorite('1')).thenThrow(Exception('offline'));

      final result = await repository.setFavorite('1', false);
      await flush();

      expect(result.fold((f) => f, (_) => null), isA<UnknownFailure>());
      expect(repository.currentFavoriteIds.isFavorite('1'), isTrue);
      expect(emitted.map((e) => e.ids).toList(), [
        <String>{},
        {'1'},
      ]);
    });

    test('404 no PUT -> notFound e rollback', () async {
      await loadWith([]);
      final response = _response(404, {'error': 'wine not found'});
      when(() => api.addFavorite('7')).thenAnswer((_) async => response);

      final result = await repository.setFavorite('7', true);

      expect(_failureCode(result), FavoriteFailureCode.notFound);
      expect(repository.currentFavoriteIds.isFavorite('7'), isFalse);
    });

    test('sem a lista carregada: rollback volta ao estado desconhecido',
        () async {
      final response = _response(500);
      when(() => api.removeFavorite('3')).thenAnswer((_) async => response);

      final future = repository.setFavorite('3', false);
      expect(repository.currentFavoriteIds.isFavorite('3'), isFalse);
      await future;

      expect(repository.currentFavoriteIds.isFavorite('3'), isNull);
    });

    test('já no estado desejado -> não chama a API', () async {
      await loadWith([1]);

      final result = await repository.setFavorite('1', true);

      expect(result.getOrElse(() => false), isTrue);
      verifyNever(() => api.addFavorite(any()));
    });

    test('só a operação mais recente do vinho decide o estado', () async {
      await loadWith([]);
      final put = Completer<Response<dynamic>>();
      final delete = Completer<Response<dynamic>>();
      when(() => api.addFavorite('1')).thenAnswer((_) => put.future);
      when(() => api.removeFavorite('1')).thenAnswer((_) => delete.future);

      final first = repository.setFavorite('1', true);
      final second = repository.setFavorite('1', false);

      // O PUT falha depois que o DELETE já foi pedido: não reverte.
      put.complete(_response(500));
      await first;
      expect(repository.currentFavoriteIds.isFavorite('1'), isFalse);

      delete.complete(_response(200, {'wine_id': 1, 'is_favorite': false}));
      await second;
      expect(repository.currentFavoriteIds.isFavorite('1'), isFalse);
    });
  });

  group('clear', () {
    test('esvazia o cache, emite e ignora respostas em voo', () async {
      await loadWith([1, 2]);
      final put = Completer<Response<dynamic>>();
      when(() => api.addFavorite('3')).thenAnswer((_) => put.future);

      final future = repository.setFavorite('3', true);
      repository.clear();
      await flush();

      expect(repository.currentFavoriteIds.isLoaded, isFalse);
      expect(repository.currentFavoriteIds.ids, isEmpty);
      expect(emitted.last.ids, isEmpty);

      put.complete(_response(500));
      await future;
      await flush();

      // A falha da sessão anterior não mexe no cache novo.
      expect(repository.currentFavoriteIds.ids, isEmpty);
      expect(repository.currentFavoriteIds.isFavorite('3'), isNull);
    });
  });

  group('getFavoritesPage', () {
    test('faz o parse da página e envia limit/offset', () async {
      final response = _response(200, {
        'favorites': [
          {
            'wine_id': 100003,
            'name': 'Cabernet Sauvignon',
            'favorited_at': '2026-09-28T19:39:13Z',
          },
        ],
        'pagination': {
          'offset': 20,
          'limit': 20,
          'total': 21,
          'has_more': false,
          'next_offset': null,
        },
      });
      when(() => api.getFavorites(limit: 20, offset: 20))
          .thenAnswer((_) async => response);

      final result = await repository.getFavoritesPage(limit: 20, offset: 20);
      final page = result.getOrElse(() => throw StateError('falhou'));

      expect(page.items.single.id, '100003');
      expect(page.offset, 20);
      expect(page.total, 21);
      expect(page.hasMore, isFalse);
    });

    test('401 -> unauthorized', () async {
      final response = _response(401);
      when(() => api.getFavorites(
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenAnswer((_) async => response);

      final result = await repository.getFavoritesPage();
      expect(_failureCode(result), FavoriteFailureCode.unauthorized);
    });
  });
}
