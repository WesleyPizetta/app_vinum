import 'package:bloc_test/bloc_test.dart';
import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/auth/domain/entity/post_auth_destination.dart';
import 'package:vinum/feature/auth/domain/entity/user.dart';
import 'package:vinum/feature/auth/domain/repository/auth_repository.dart';
import 'package:vinum/feature/auth/domain/usecase/ensure_user_nickname.dart';
import 'package:vinum/feature/auth/domain/usecase/sign_in.dart';
import 'package:vinum/feature/auth/presentation/bloc/login_bloc.dart';
import 'package:vinum/feature/auth/presentation/bloc/login_event.dart';
import 'package:vinum/feature/auth/presentation/bloc/login_state.dart';

class MockSignIn extends Mock implements SignIn {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockEnsureUserNickname extends Mock implements EnsureUserNickname {}

const _tUser = User(id: '1', email: 'test@example.com', name: 'Test User');

void main() {
  late MockSignIn mockSignIn;
  late MockAuthRepository mockAuthRepository;
  late MockEnsureUserNickname mockEnsureUserNickname;

  setUpAll(() {
    registerFallbackValue(const SignInParams(email: '', password: ''));
    registerFallbackValue(_tUser);
  });

  setUp(() {
    mockSignIn = MockSignIn();
    mockAuthRepository = MockAuthRepository();
    mockEnsureUserNickname = MockEnsureUserNickname();
    // Por padrão o gate de apelido devolve o usuário como veio.
    when(() => mockEnsureUserNickname(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as User,
    );
  });

  // ─── LoginSessionChecked ──────────────────────────────────────────────────

  group('LoginSessionChecked', () {
    blocTest<LoginBloc, LoginState>(
      'emits [LoginLoading, LoginSuccess] quando a sessão restaurada é válida',
      build: () {
        when(() => mockAuthRepository.restoreSession())
            .thenAnswer((_) async => _tUser.copyWith(onboardingCompleted: true));
        return LoginBloc(mockSignIn, mockAuthRepository, mockEnsureUserNickname);
      },
      act: (bloc) => bloc.add(LoginSessionChecked()),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>()
            .having((s) => s.user.email, 'email', _tUser.email)
            .having((s) => s.user.onboardingCompleted, 'onboarding', true),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'volta para LoginInitial quando não há sessão válida',
      build: () {
        when(() => mockAuthRepository.restoreSession())
            .thenAnswer((_) async => null);
        return LoginBloc(mockSignIn, mockAuthRepository, mockEnsureUserNickname);
      },
      act: (bloc) => bloc.add(LoginSessionChecked()),
      expect: () => [isA<LoginLoading>(), isA<LoginInitial>()],
      verify: (_) => verifyNever(() => mockEnsureUserNickname(any())),
    );

    blocTest<LoginBloc, LoginState>(
      'aplica o apelido do cadastro e segue para o quiz',
      build: () {
        when(() => mockAuthRepository.restoreSession())
            .thenAnswer((_) async => _tUser);
        when(() => mockEnsureUserNickname(any())).thenAnswer(
          (_) async => _tUser.copyWith(nickname: 'test_user'),
        );
        return LoginBloc(mockSignIn, mockAuthRepository, mockEnsureUserNickname);
      },
      act: (bloc) => bloc.add(LoginSessionChecked()),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>()
            .having((s) => s.user.nickname, 'nickname', 'test_user')
            .having((s) => s.destination, 'destination',
                PostAuthDestination.onboarding),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'sem apelido, o destino é a tela de apelido',
      build: () {
        when(() => mockAuthRepository.restoreSession())
            .thenAnswer((_) async => _tUser.copyWith(onboardingCompleted: true));
        return LoginBloc(mockSignIn, mockAuthRepository, mockEnsureUserNickname);
      },
      act: (bloc) => bloc.add(LoginSessionChecked()),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>().having((s) => s.destination, 'destination',
            PostAuthDestination.nickname),
      ],
    );
  });

  // ─── LoginSubmitted ───────────────────────────────────────────────────────

  group('LoginSubmitted', () {
    blocTest<LoginBloc, LoginState>(
      'emite [LoginLoading, LoginSuccess] em caso de sucesso',
      build: () {
        when(() => mockAuthRepository.getCurrentUser()).thenReturn(null);
        when(() => mockSignIn(any()))
            .thenAnswer((_) async => Try.success(_tUser));
        return LoginBloc(mockSignIn, mockAuthRepository, mockEnsureUserNickname);
      },
      act: (bloc) => bloc.add(
        LoginSubmitted(email: 'test@example.com', password: '123456'),
      ),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>().having((s) => s.user.id, 'id', _tUser.id),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'emite [LoginLoading, LoginError] com mensagem de credenciais inválidas',
      build: () {
        when(() => mockAuthRepository.getCurrentUser()).thenReturn(null);
        when(() => mockSignIn(any())).thenAnswer(
          (_) async => Try.reject(
            KnownFailure('AUTH', null, message: 'Invalid credentials'),
          ),
        );
        return LoginBloc(mockSignIn, mockAuthRepository, mockEnsureUserNickname);
      },
      act: (bloc) => bloc.add(
        LoginSubmitted(email: 'wrong@test.com', password: 'wrong'),
      ),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginError>().having(
          (s) => s.message,
          'message',
          'auth_error_invalid_credentials',
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'emite [LoginLoading, LoginError] com mensagem de e-mail não confirmado',
      build: () {
        when(() => mockAuthRepository.getCurrentUser()).thenReturn(null);
        when(() => mockSignIn(any())).thenAnswer(
          (_) async => Try.reject(
            KnownFailure('AUTH', null, message: 'Email not confirmed'),
          ),
        );
        return LoginBloc(mockSignIn, mockAuthRepository, mockEnsureUserNickname);
      },
      act: (bloc) => bloc.add(
        LoginSubmitted(email: 'unconfirmed@test.com', password: '123456'),
      ),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginError>().having(
          (s) => s.message,
          'message',
          'auth_error_email_not_confirmed',
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'emite [LoginLoading, LoginError] com mensagem genérica em falha desconhecida',
      build: () {
        when(() => mockAuthRepository.getCurrentUser()).thenReturn(null);
        when(() => mockSignIn(any())).thenAnswer(
          (_) async => Try.reject(UnknownFailure(Exception('network error'))),
        );
        return LoginBloc(mockSignIn, mockAuthRepository, mockEnsureUserNickname);
      },
      act: (bloc) => bloc.add(
        LoginSubmitted(email: 'test@test.com', password: '123456'),
      ),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginError>()
            .having((s) => s.message, 'message', 'error_generic'),
      ],
    );
  });

  // ─── LoginSocialSubmitted ─────────────────────────────────────────────────

  group('LoginSocialSubmitted', () {
    blocTest<LoginBloc, LoginState>(
      'emite [LoginLoading, LoginSuccess] em login social bem-sucedido',
      build: () {
        when(() => mockAuthRepository.getCurrentUser()).thenReturn(null);
        when(() => mockAuthRepository.signInWithSocial(
              provider: any(named: 'provider'),
              idToken: any(named: 'idToken'),
              nonce: any(named: 'nonce'),
            )).thenAnswer((_) async => Try.success(_tUser));
        return LoginBloc(mockSignIn, mockAuthRepository, mockEnsureUserNickname);
      },
      act: (bloc) => bloc.add(
        LoginSocialSubmitted(provider: 'google', idToken: 'valid_token_123'),
      ),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginSuccess>(),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      'emite [LoginLoading, LoginError] com mensagem de falha social',
      build: () {
        when(() => mockAuthRepository.getCurrentUser()).thenReturn(null);
        when(() => mockAuthRepository.signInWithSocial(
              provider: any(named: 'provider'),
              idToken: any(named: 'idToken'),
              nonce: any(named: 'nonce'),
            )).thenAnswer(
          (_) async => Try.reject(
            KnownFailure('SOCIAL', null,
                message: 'social token exchange failed'),
          ),
        );
        return LoginBloc(mockSignIn, mockAuthRepository, mockEnsureUserNickname);
      },
      act: (bloc) => bloc.add(
        LoginSocialSubmitted(provider: 'google', idToken: 'invalid_token'),
      ),
      expect: () => [
        isA<LoginLoading>(),
        isA<LoginError>().having(
          (s) => s.message,
          'message',
          'auth_error_social_login_failed',
        ),
      ],
    );
  });
}
