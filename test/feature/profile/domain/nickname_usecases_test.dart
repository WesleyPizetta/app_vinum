import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/auth/domain/repository/auth_repository.dart';
import 'package:vinum/feature/profile/domain/entity/nickname_availability.dart';
import 'package:vinum/feature/profile/domain/entity/nickname_failure_code.dart';
import 'package:vinum/feature/profile/domain/repository/nickname_repository.dart';
import 'package:vinum/feature/profile/domain/usecase/check_nickname_availability.dart';
import 'package:vinum/feature/profile/domain/usecase/set_my_nickname.dart';

class MockNicknameRepository extends Mock implements NicknameRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

String? _failureCode(Try<Object?> result) =>
    result.fold((failure) => failure.code, (_) => null);

void main() {
  late MockNicknameRepository repository;
  late MockAuthRepository authRepository;

  setUpAll(() => registerFallbackValue(''));

  setUp(() {
    repository = MockNicknameRepository();
    authRepository = MockAuthRepository();
  });

  group('CheckNicknameAvailability', () {
    test('normaliza a entrada antes de consultar', () async {
      when(() => repository.checkAvailability('wes_pizetta')).thenAnswer(
        (_) async => Try.success(const NicknameAvailability(
          nickname: 'wes_pizetta',
          available: true,
        )),
      );

      final result =
          await CheckNicknameAvailability(repository)('@Wes_Pizetta');

      expect(result.getOrElse(() => throw StateError('falhou')).available,
          isTrue);
      verify(() => repository.checkAvailability('wes_pizetta')).called(1);
    });

    test('regra local violada não chama o servidor', () async {
      final result = await CheckNicknameAvailability(repository)('ab');

      expect(
        result.getOrElse(() => throw StateError('falhou')),
        const NicknameAvailability(
          nickname: 'ab',
          available: false,
          code: NicknameFailureCode.tooShort,
        ),
      );
      verifyNever(() => repository.checkAvailability(any()));
    });
  });

  group('SetMyNickname', () {
    test('salva e atualiza o usuário em cache', () async {
      when(() => repository.setMyNickname('wes_pizetta'))
          .thenAnswer((_) async => Try.success('wes_pizetta'));
      when(() => authRepository.updateCurrentUserNickname('wes_pizetta'))
          .thenAnswer((_) async => null);

      final result =
          await SetMyNickname(repository, authRepository)('@Wes_Pizetta');

      expect(result.getOrElse(() => ''), 'wes_pizetta');
      verify(() => authRepository.updateCurrentUserNickname('wes_pizetta'))
          .called(1);
    });

    test('falha do servidor não altera o cache', () async {
      when(() => repository.setMyNickname('wes')).thenAnswer(
        (_) async =>
            Try.reject(KnownFailure(NicknameFailureCode.taken, null)),
      );

      final result = await SetMyNickname(repository, authRepository)('wes');

      expect(_failureCode(result), NicknameFailureCode.taken);
      verifyNever(() => authRepository.updateCurrentUserNickname(any()));
    });

    test('regra local violada falha sem chamar o servidor', () async {
      final result =
          await SetMyNickname(repository, authRepository)('wes..p');

      expect(_failureCode(result), NicknameFailureCode.invalidFormat);
      verifyNever(() => repository.setMyNickname(any()));
    });
  });
}
