import 'package:bloc_test/bloc_test.dart';
import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/auth/domain/entity/sign_up_result.dart';
import 'package:vinum/feature/auth/domain/entity/user.dart';
import 'package:vinum/feature/auth/domain/usecase/sign_up.dart';
import 'package:vinum/feature/auth/presentation/bloc/register_bloc.dart';
import 'package:vinum/feature/auth/presentation/bloc/register_event.dart';
import 'package:vinum/feature/auth/presentation/bloc/register_state.dart';

class MockSignUp extends Mock implements SignUp {}

const _tUser = User(id: '2', email: 'new@example.com', name: 'New User');
const _tSignUpResult =
    SignUpResult(user: _tUser, requiresEmailConfirmation: false);

void main() {
  late MockSignUp mockSignUp;

  setUpAll(() {
    registerFallbackValue(
      const SignUpParams(email: '', password: '', name: ''),
    );
  });

  setUp(() {
    mockSignUp = MockSignUp();
  });

  group('RegisterSubmitted', () {
    blocTest<RegisterBloc, RegisterState>(
      'emite [RegisterLoading, RegisterSuccess] em caso de sucesso',
      build: () {
        when(() => mockSignUp(any()))
            .thenAnswer((_) async => Try.success(_tSignUpResult));
        return RegisterBloc(mockSignUp);
      },
      act: (bloc) => bloc.add(
        RegisterSubmitted(
          name: 'New User',
          email: 'new@example.com',
          password: '123456',
          nickname: 'new_user',
        ),
      ),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterSuccess>()
            .having((s) => s.user.email, 'email', _tUser.email)
            .having((s) => s.requiresEmailConfirmation, 'confirm', false),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'sinaliza confirmação de e-mail quando não há sessão',
      build: () {
        when(() => mockSignUp(any())).thenAnswer((_) async => Try.success(
              const SignUpResult(user: _tUser, requiresEmailConfirmation: true),
            ));
        return RegisterBloc(mockSignUp);
      },
      act: (bloc) => bloc.add(
        RegisterSubmitted(
          name: 'New User',
          email: 'new@example.com',
          password: '123456',
          nickname: 'new_user',
        ),
      ),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterSuccess>()
            .having((s) => s.requiresEmailConfirmation, 'confirm', true),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'emite [RegisterLoading, RegisterError] quando e-mail já está cadastrado',
      build: () {
        when(() => mockSignUp(any())).thenAnswer(
          (_) async => Try.reject(
            KnownFailure('EMAIL_IN_USE', null,
                message: 'User already registered'),
          ),
        );
        return RegisterBloc(mockSignUp);
      },
      act: (bloc) => bloc.add(
        RegisterSubmitted(
          name: 'Test User',
          email: 'existing@example.com',
          password: '123456',
          nickname: 'new_user',
        ),
      ),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterError>().having(
          (s) => s.message,
          'message',
          'auth_error_email_in_use',
        ),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'emite [RegisterLoading, RegisterError] com mensagem de senha fraca',
      build: () {
        when(() => mockSignUp(any())).thenAnswer(
          (_) async => Try.reject(
            KnownFailure('WEAK_PASS', null,
                message: 'Password should be at least 6 characters'),
          ),
        );
        return RegisterBloc(mockSignUp);
      },
      act: (bloc) => bloc.add(
        RegisterSubmitted(
          name: 'Test',
          email: 'test@example.com',
          password: '123',
          nickname: 'test',
        ),
      ),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterError>().having(
          (s) => s.message,
          'message',
          'auth_error_weak_password',
        ),
      ],
    );

    blocTest<RegisterBloc, RegisterState>(
      'emite [RegisterLoading, RegisterError] com mensagem genérica em falha desconhecida',
      build: () {
        when(() => mockSignUp(any())).thenAnswer(
          (_) async =>
              Try.reject(UnknownFailure(Exception('server error'))),
        );
        return RegisterBloc(mockSignUp);
      },
      act: (bloc) => bloc.add(
        RegisterSubmitted(
          name: 'Test',
          email: 'test@example.com',
          password: '123456',
          nickname: 'new_user',
        ),
      ),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterError>()
            .having((s) => s.message, 'message', 'error_generic'),
      ],
    );
  });

  group('RegisterSubmitted - apelido', () {
    blocTest<RegisterBloc, RegisterState>(
      'envia o apelido normalizado (sem "@", minúsculo) ao cadastro',
      build: () {
        when(() => mockSignUp(any()))
            .thenAnswer((_) async => Try.success(_tSignUpResult));
        return RegisterBloc(mockSignUp);
      },
      act: (bloc) => bloc.add(
        RegisterSubmitted(
          name: 'Wes Pizetta',
          email: 'wes@example.com',
          password: '123456',
          nickname: '  @Wes_Pizetta ',
        ),
      ),
      expect: () => [isA<RegisterLoading>(), isA<RegisterSuccess>()],
      verify: (_) {
        final params = verify(() => mockSignUp(captureAny()))
            .captured
            .single as SignUpParams;
        expect(params.nickname, 'wes_pizetta');
        expect(params.name, 'Wes Pizetta');
        expect(params.email, 'wes@example.com');
      },
    );

    blocTest<RegisterBloc, RegisterState>(
      'apelido inválido emite RegisterError sem chamar o cadastro',
      build: () => RegisterBloc(mockSignUp),
      act: (bloc) => bloc.add(
        RegisterSubmitted(
          name: 'Jo',
          email: 'jo@example.com',
          password: '123456',
          nickname: 'jo',
        ),
      ),
      expect: () => [
        isA<RegisterError>().having(
          (s) => s.message,
          'message',
          'nickname_error_too_short',
        ),
      ],
      verify: (_) => verifyNever(() => mockSignUp(any())),
    );

    blocTest<RegisterBloc, RegisterState>(
      'apelido vazio emite RegisterError de apelido obrigatório',
      build: () => RegisterBloc(mockSignUp),
      act: (bloc) => bloc.add(
        RegisterSubmitted(
          name: 'Ana',
          email: 'ana@example.com',
          password: '123456',
          nickname: '',
        ),
      ),
      expect: () => [
        isA<RegisterError>().having(
          (s) => s.message,
          'message',
          'nickname_error_required',
        ),
      ],
      verify: (_) => verifyNever(() => mockSignUp(any())),
    );
  });
}
