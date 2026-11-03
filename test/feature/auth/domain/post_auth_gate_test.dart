import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/auth/domain/entity/post_auth_destination.dart';
import 'package:vinum/feature/auth/domain/entity/user.dart';
import 'package:vinum/feature/auth/domain/repository/auth_repository.dart';
import 'package:vinum/feature/auth/domain/usecase/ensure_user_nickname.dart';
import 'package:vinum/feature/profile/domain/entity/nickname_failure_code.dart';
import 'package:vinum/feature/profile/domain/usecase/set_my_nickname.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSetMyNickname extends Mock implements SetMyNickname {}

const _tUser = User(id: '1', email: 'wes@example.com', name: 'Wes Pizetta');

void main() {
  setUpAll(() => registerFallbackValue(''));

  group('PostAuthDestination.forUser', () {
    test('sem apelido vai para a tela de apelido (antes do quiz)', () {
      expect(PostAuthDestination.forUser(_tUser), PostAuthDestination.nickname);
      expect(
        PostAuthDestination.forUser(
          _tUser.copyWith(onboardingCompleted: true, nickname: '  '),
        ),
        PostAuthDestination.nickname,
      );
    });

    test('com apelido e quiz pendente vai para o onboarding', () {
      expect(
        PostAuthDestination.forUser(_tUser.copyWith(nickname: 'wes')),
        PostAuthDestination.onboarding,
      );
    });

    test('com apelido e quiz feito vai para a home', () {
      expect(
        PostAuthDestination.forUser(
          _tUser.copyWith(nickname: 'wes', onboardingCompleted: true),
        ),
        PostAuthDestination.home,
      );
    });
  });

  group('EnsureUserNickname', () {
    late MockAuthRepository authRepository;
    late MockSetMyNickname setMyNickname;
    late EnsureUserNickname ensure;

    setUp(() {
      authRepository = MockAuthRepository();
      setMyNickname = MockSetMyNickname();
      ensure = EnsureUserNickname(authRepository, setMyNickname);
    });

    test('usuário com apelido não faz nada', () async {
      final user = _tUser.copyWith(nickname: 'wes');

      expect(await ensure(user), same(user));
      verifyNever(() => authRepository.getSignUpNickname());
      verifyNever(() => setMyNickname(any()));
    });

    test('aplica o apelido dos metadados do cadastro', () async {
      when(() => authRepository.getSignUpNickname()).thenReturn('wes_pizetta');
      when(() => setMyNickname('wes_pizetta'))
          .thenAnswer((_) async => Try.success('wes_pizetta'));
      when(() => authRepository.getCurrentUser())
          .thenReturn(_tUser.copyWith(nickname: 'wes_pizetta'));

      final result = await ensure(_tUser);

      expect(result.nickname, 'wes_pizetta');
      expect(PostAuthDestination.forUser(result),
          PostAuthDestination.onboarding);
    });

    test('sem metadados devolve o usuário sem apelido', () async {
      when(() => authRepository.getSignUpNickname()).thenReturn(null);

      final result = await ensure(_tUser);

      expect(result.hasNickname, isFalse);
      verifyNever(() => setMyNickname(any()));
    });

    test('metadados inválidos são ignorados', () async {
      when(() => authRepository.getSignUpNickname()).thenReturn('a b');

      final result = await ensure(_tUser);

      expect(result.hasNickname, isFalse);
      verifyNever(() => setMyNickname(any()));
    });

    test('falha ao salvar (ex.: em uso) leva à tela de apelido', () async {
      when(() => authRepository.getSignUpNickname()).thenReturn('wes');
      when(() => setMyNickname('wes')).thenAnswer(
        (_) async =>
            Try.reject(KnownFailure(NicknameFailureCode.taken, null)),
      );

      final result = await ensure(_tUser);

      expect(PostAuthDestination.forUser(result),
          PostAuthDestination.nickname);
    });
  });
}
