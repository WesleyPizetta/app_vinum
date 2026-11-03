import 'dart:convert';

import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
// `http` já vem com o chopper (dependência transitiva); só a
// `http.Response` base é necessária para montar a resposta Chopper.
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/profile/data/api/profile_api_service.dart';
import 'package:vinum/feature/profile/data/repository/nickname_repository_impl.dart';
import 'package:vinum/feature/profile/domain/entity/nickname_availability.dart';
import 'package:vinum/feature/profile/domain/entity/nickname_failure_code.dart';

class MockProfileApiService extends Mock implements ProfileApiService {}

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
  late MockProfileApiService api;
  late NicknameRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() {
    api = MockProfileApiService();
    repository = NicknameRepositoryImpl(api);
  });

  group('checkAvailability', () {
    test('disponível', () async {
      final response = _response(200, {'nickname': 'wes', 'available': true});
      when(() => api.checkNickname('wes')).thenAnswer((_) async => response);

      final result = await repository.checkAvailability('wes');

      expect(
        result.getOrElse(() => throw StateError('falhou')),
        const NicknameAvailability(nickname: 'wes', available: true),
      );
    });

    test('em uso', () async {
      final response = _response(200, {
        'nickname': 'wes',
        'available': false,
        'code': 'NICKNAME_TAKEN',
      });
      when(() => api.checkNickname('wes')).thenAnswer((_) async => response);

      final result = await repository.checkAvailability('wes');

      expect(
        result.getOrElse(() => throw StateError('falhou')).code,
        NicknameFailureCode.taken,
      );
    });

    test('422 com código de regra vira indisponível', () async {
      final response = _response(422, {
        'error': 'nickname is offensive',
        'code': 'NICKNAME_OFFENSIVE',
      });
      when(() => api.checkNickname('xxx')).thenAnswer((_) async => response);

      final result = await repository.checkAvailability('xxx');

      expect(
        result.getOrElse(() => throw StateError('falhou')),
        const NicknameAvailability(
          nickname: 'xxx',
          available: false,
          code: NicknameFailureCode.offensive,
        ),
      );
    });

    test('exceção de transporte -> falha de rede', () async {
      when(() => api.checkNickname('wes'))
          .thenThrow(Exception('SocketException'));

      final result = await repository.checkAvailability('wes');

      expect(_failureCode(result), NicknameFailureCode.network);
    });

    test('corpo fora do contrato', () async {
      final response = _response(200, {'foo': 'bar'});
      when(() => api.checkNickname('wes')).thenAnswer((_) async => response);

      final result = await repository.checkAvailability('wes');

      expect(_failureCode(result), NicknameFailureCode.invalidResponse);
    });
  });

  group('setMyNickname', () {
    test('envia o corpo e retorna o apelido salvo', () async {
      final response = _response(200, {'nickname': 'wes_pizetta'});
      when(() => api.setMyNickname(any())).thenAnswer((_) async => response);

      final result = await repository.setMyNickname('wes_pizetta');

      expect(result.getOrElse(() => ''), 'wes_pizetta');
      final body = verify(() => api.setMyNickname(captureAny()))
          .captured
          .single as Map<String, dynamic>;
      expect(body, {'nickname': 'wes_pizetta'});
    });

    test('409 -> NICKNAME_TAKEN', () async {
      final response = _response(409, {
        'error': 'nickname already taken',
        'code': 'NICKNAME_TAKEN',
      });
      when(() => api.setMyNickname(any())).thenAnswer((_) async => response);

      final result = await repository.setMyNickname('wes');

      expect(_failureCode(result), NicknameFailureCode.taken);
    });

    test('422 usa o código do corpo', () async {
      final response = _response(422, {
        'error': 'reserved',
        'code': 'NICKNAME_RESERVED',
      });
      when(() => api.setMyNickname(any())).thenAnswer((_) async => response);

      final result = await repository.setMyNickname('admin');

      expect(_failureCode(result), NicknameFailureCode.reserved);
    });

    test('401 -> não autorizado; 5xx -> servidor', () async {
      final unauthorized = _response(401, {'error': 'unauthorized'});
      when(() => api.setMyNickname(any()))
          .thenAnswer((_) async => unauthorized);
      expect(
        _failureCode(await repository.setMyNickname('wes')),
        NicknameFailureCode.unauthorized,
      );

      final server = _response(500, {'error': 'boom'});
      when(() => api.setMyNickname(any())).thenAnswer((_) async => server);
      expect(
        _failureCode(await repository.setMyNickname('wes')),
        NicknameFailureCode.server,
      );
    });

    test('exceção de transporte -> falha de rede', () async {
      when(() => api.setMyNickname(any())).thenThrow(Exception('offline'));

      final result = await repository.setMyNickname('wes');

      expect(_failureCode(result), NicknameFailureCode.network);
    });
  });
}
