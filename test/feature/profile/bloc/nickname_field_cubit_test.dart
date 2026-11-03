import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:essentials/essentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vinum/feature/profile/domain/entity/nickname_availability.dart';
import 'package:vinum/feature/profile/domain/entity/nickname_failure_code.dart';
import 'package:vinum/feature/profile/domain/usecase/check_nickname_availability.dart';
import 'package:vinum/feature/profile/presentation/bloc/nickname_field_cubit.dart';
import 'package:vinum/feature/profile/presentation/bloc/nickname_field_state.dart';

class MockCheckNicknameAvailability extends Mock
    implements CheckNicknameAvailability {}

const _debounce = Duration(milliseconds: 20);

Future<Try<NicknameAvailability>> _available(String nickname) async =>
    Try.success(NicknameAvailability(nickname: nickname, available: true));

Future<Try<NicknameAvailability>> _unavailable(
  String nickname,
  String code,
) async =>
    Try.success(NicknameAvailability(
      nickname: nickname,
      available: false,
      code: code,
    ));

NicknameFieldState _state(
  String nickname,
  NicknameFieldStatus status, [
  String? errorCode,
]) =>
    NicknameFieldState(
      nickname: nickname,
      status: status,
      errorCode: errorCode,
    );

void main() {
  late MockCheckNicknameAvailability check;

  setUpAll(() => registerFallbackValue(''));

  setUp(() {
    check = MockCheckNicknameAvailability();
  });

  NicknameFieldCubit build() => NicknameFieldCubit(check, debounce: _debounce);

  group('validação local', () {
    blocTest<NicknameFieldCubit, NicknameFieldState>(
      'apelido curto fica inválido sem consultar o servidor',
      build: build,
      act: (cubit) => cubit.changed('wa'),
      wait: _debounce * 3,
      expect: () => [
        _state('wa', NicknameFieldStatus.invalid, NicknameFailureCode.tooShort),
      ],
      verify: (_) => verifyNever(() => check(any())),
    );

    blocTest<NicknameFieldCubit, NicknameFieldState>(
      'normaliza "@" e maiúsculas',
      build: () {
        when(() => check('wes_pizetta'))
            .thenAnswer((_) => _available('wes_pizetta'));
        return build();
      },
      act: (cubit) => cubit.changed('@Wes_Pizetta'),
      wait: _debounce * 3,
      expect: () => [
        _state('wes_pizetta', NicknameFieldStatus.checking),
        _state('wes_pizetta', NicknameFieldStatus.available),
      ],
    );

    blocTest<NicknameFieldCubit, NicknameFieldState>(
      'campo vazio só mostra "obrigatório" após tentativa de envio',
      build: build,
      act: (cubit) {
        cubit.changed('');
        cubit.submitAttempted();
      },
      expect: () => [
        _state('', NicknameFieldStatus.invalid, NicknameFailureCode.required),
      ],
    );
  });

  group('disponibilidade', () {
    blocTest<NicknameFieldCubit, NicknameFieldState>(
      'disponível',
      build: () {
        when(() => check('wes')).thenAnswer((_) => _available('wes'));
        return build();
      },
      act: (cubit) => cubit.changed('wes'),
      wait: _debounce * 3,
      expect: () => [
        _state('wes', NicknameFieldStatus.checking),
        _state('wes', NicknameFieldStatus.available),
      ],
    );

    blocTest<NicknameFieldCubit, NicknameFieldState>(
      'em uso',
      build: () {
        when(() => check('wes'))
            .thenAnswer((_) => _unavailable('wes', NicknameFailureCode.taken));
        return build();
      },
      act: (cubit) => cubit.changed('wes'),
      wait: _debounce * 3,
      expect: () => [
        _state('wes', NicknameFieldStatus.checking),
        _state('wes', NicknameFieldStatus.unavailable,
            NicknameFailureCode.taken),
      ],
    );

    blocTest<NicknameFieldCubit, NicknameFieldState>(
      'ofensivo',
      build: () {
        when(() => check('xingamento')).thenAnswer(
          (_) => _unavailable('xingamento', NicknameFailureCode.offensive),
        );
        return build();
      },
      act: (cubit) => cubit.changed('xingamento'),
      wait: _debounce * 3,
      expect: () => [
        _state('xingamento', NicknameFieldStatus.checking),
        _state('xingamento', NicknameFieldStatus.unavailable,
            NicknameFailureCode.offensive),
      ],
    );

    blocTest<NicknameFieldCubit, NicknameFieldState>(
      'falha de rede vira erro (e permite tentar de novo)',
      build: () {
        when(() => check('wes')).thenAnswer(
          (_) async =>
              Try.reject(KnownFailure(NicknameFailureCode.network, null)),
        );
        return build();
      },
      act: (cubit) async {
        cubit.changed('wes');
        await Future<void>.delayed(_debounce * 3);
        cubit.changed('wes'); // mesmo texto: tenta de novo após erro
      },
      wait: _debounce * 3,
      expect: () => [
        _state('wes', NicknameFieldStatus.checking),
        _state('wes', NicknameFieldStatus.error, NicknameFailureCode.network),
        _state('wes', NicknameFieldStatus.checking),
        _state('wes', NicknameFieldStatus.error, NicknameFailureCode.network),
      ],
      verify: (_) => verify(() => check('wes')).called(2),
    );

    blocTest<NicknameFieldCubit, NicknameFieldState>(
      'apelido atual do usuário é disponível sem consultar',
      build: build,
      act: (cubit) => cubit.start(initial: 'wes', ownNickname: 'wes'),
      wait: _debounce * 3,
      expect: () => [_state('wes', NicknameFieldStatus.available)],
      verify: (_) => verifyNever(() => check(any())),
    );
  });

  group('debounce e respostas antigas', () {
    blocTest<NicknameFieldCubit, NicknameFieldState>(
      'digitação rápida consulta só o último texto',
      build: () {
        when(() => check(any())).thenAnswer(
          (invocation) =>
              _available(invocation.positionalArguments.first as String),
        );
        return build();
      },
      act: (cubit) {
        cubit.changed('wes');
        cubit.changed('wesp');
        cubit.changed('wespi');
      },
      wait: _debounce * 3,
      expect: () => [
        _state('wes', NicknameFieldStatus.checking),
        _state('wesp', NicknameFieldStatus.checking),
        _state('wespi', NicknameFieldStatus.checking),
        _state('wespi', NicknameFieldStatus.available),
      ],
      verify: (_) {
        verify(() => check('wespi')).called(1);
        verifyNever(() => check('wes'));
        verifyNever(() => check('wesp'));
      },
    );

    final slowResponse = Completer<Try<NicknameAvailability>>();
    blocTest<NicknameFieldCubit, NicknameFieldState>(
      'ignora a resposta de um texto que já mudou',
      build: () {
        when(() => check('wes')).thenAnswer((_) => slowResponse.future);
        when(() => check('wesley'))
            .thenAnswer((_) => _unavailable('wesley', NicknameFailureCode.taken));
        return build();
      },
      act: (cubit) async {
        cubit.changed('wes');
        // Debounce vence: a consulta de "wes" fica em voo.
        await Future<void>.delayed(_debounce * 2);
        cubit.changed('wesley');
        await Future<void>.delayed(_debounce * 3);
        // Só agora chega a resposta antiga ("wes" disponível).
        slowResponse.complete(Try.success(
          const NicknameAvailability(nickname: 'wes', available: true),
        ));
      },
      wait: _debounce * 2,
      expect: () => [
        _state('wes', NicknameFieldStatus.checking),
        _state('wesley', NicknameFieldStatus.checking),
        _state('wesley', NicknameFieldStatus.unavailable,
            NicknameFailureCode.taken),
      ],
      verify: (_) => verify(() => check('wes')).called(1),
    );

    blocTest<NicknameFieldCubit, NicknameFieldState>(
      'recusa do servidor ao salvar marca o apelido como indisponível',
      build: () {
        when(() => check('wes')).thenAnswer((_) => _available('wes'));
        return build();
      },
      act: (cubit) async {
        cubit.changed('wes');
        await Future<void>.delayed(_debounce * 3);
        cubit.rejectedByServer('wes', NicknameFailureCode.taken);
        cubit.rejectedByServer('outro', NicknameFailureCode.taken); // ignorado
      },
      expect: () => [
        _state('wes', NicknameFieldStatus.checking),
        _state('wes', NicknameFieldStatus.available),
        _state('wes', NicknameFieldStatus.unavailable,
            NicknameFailureCode.taken),
      ],
    );
  });
}
