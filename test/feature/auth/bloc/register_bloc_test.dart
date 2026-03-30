import 'package:bloc_test/bloc_test.dart';
import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/auth/domain/entity/user.dart';
import 'package:vinum/feature/auth/domain/usecase/sign_up.dart';
import 'package:vinum/feature/auth/presentation/bloc/register_bloc.dart';
import 'package:vinum/feature/auth/presentation/bloc/register_event.dart';
import 'package:vinum/feature/auth/presentation/bloc/register_state.dart';

class MockSignUp extends Mock implements SignUp {}

const _tUser = User(id: '2', email: 'new@example.com', name: 'New User');

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
            .thenAnswer((_) async => Try.success(_tUser));
        return RegisterBloc(mockSignUp);
      },
      act: (bloc) => bloc.add(
        RegisterSubmitted(
          name: 'New User',
          email: 'new@example.com',
          password: '123456',
        ),
      ),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterSuccess>()
            .having((s) => s.user.email, 'email', _tUser.email),
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
        ),
      ),
      expect: () => [
        isA<RegisterLoading>(),
        isA<RegisterError>()
            .having((s) => s.message, 'message', 'error_generic'),
      ],
    );
  });
}
