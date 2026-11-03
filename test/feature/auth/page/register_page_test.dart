import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vinum/feature/auth/presentation/bloc/register_bloc.dart';
import 'package:vinum/feature/auth/presentation/bloc/register_event.dart';
import 'package:vinum/feature/auth/presentation/bloc/register_state.dart';
import 'package:vinum/feature/auth/presentation/page/register_page.dart';
import 'package:vinum/feature/profile/domain/entity/nickname_availability.dart';
import 'package:vinum/feature/profile/domain/usecase/check_nickname_availability.dart';
import 'package:vinum/feature/profile/presentation/bloc/nickname_field_cubit.dart';
import 'package:vinum/feature/profile/presentation/widget/nickname_field.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

/// Bloc falso que captura eventos sem alterar estado, útil para widget tests.
class _FakeRegisterBloc extends Bloc<RegisterEvent, RegisterState>
    implements RegisterBloc {
  final capturedEvents = <RegisterEvent>[];

  _FakeRegisterBloc(super.initialState) {
    on<RegisterSubmitted>((e, _) => capturedEvents.add(e));
  }
}

/// Verificação de apelido controlável: disponível por padrão.
class _FakeCheckNicknameAvailability implements CheckNicknameAvailability {
  bool available = true;
  String unavailableCode = 'NICKNAME_TAKEN';
  final requested = <String>[];

  @override
  Future<Try<NicknameAvailability>> call(String params) async {
    requested.add(params);
    return Try.success(NicknameAvailability(
      nickname: params,
      available: available,
      code: available ? null : unavailableCode,
    ));
  }
}

class _FakeEnvironment extends Fake implements Environment {
  @override
  bool get isProduction => false;
  @override
  String get apiUrl => 'http://localhost:8080';
  @override
  String get name => 'test';
  @override
  String get googleWebClientId => '';
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Widget _buildApp(Widget home) => MaterialApp(
      localizationsDelegates: [
        AppLocalizationDelegate(
            supportedLocales: const [Locale('pt', 'BR')]),
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
      onGenerateRoute: (_) =>
          MaterialPageRoute(builder: (_) => const Scaffold()),
      home: home,
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'vinum',
      packageName: 'com.vinum',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  late _FakeCheckNicknameAvailability checkNickname;

  Future<_FakeRegisterBloc> pumpPage(
    WidgetTester tester,
    RegisterState initialState, {
    bool settle = true,
    bool nicknameAvailable = true,
  }) async {
    final bloc = _FakeRegisterBloc(initialState);
    checkNickname = _FakeCheckNicknameAvailability()
      ..available = nicknameAvailable;
    await ApplicationContainer.reset();
    ApplicationContainer.registerFactory<RegisterBloc>(() => bloc);
    ApplicationContainer.registerFactory<NicknameFieldCubit>(
      () => NicknameFieldCubit(checkNickname, debounce: Duration.zero),
    );
    ApplicationContainer.registerSingleton<Environment>(_FakeEnvironment());
    // Limpa a árvore de widgets anterior antes de construir a nova
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await tester.pumpWidget(_buildApp(RegisterPage(key: UniqueKey())));
    });
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return bloc;
  }

  tearDownAll(() async => ApplicationContainer.reset());

  // ── Renderização ──────────────────────────────────────────────────────────

  testWidgets('exibe campos de nome, apelido, e-mail e senha', (tester) async {
    await pumpPage(tester, RegisterInitial());

    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.byKey(NicknameField.fieldKey), findsOneWidget);
    expect(find.text('Como você quer ser chamado?'), findsOneWidget);
  });

  // ── Validação de formulário ───────────────────────────────────────────────

  testWidgets('exibe erro ao submeter com nome vazio', (tester) async {
    await pumpPage(tester, RegisterInitial());

    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    expect(find.text('Informe o nome.'), findsOneWidget);
  });

  testWidgets('exibe erro ao submeter com e-mail vazio', (tester) async {
    await pumpPage(tester, RegisterInitial());

    await tester.enterText(find.byType(TextFormField).at(0), 'João Silva');
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    expect(find.text('Informe o e-mail.'), findsOneWidget);
  });

  testWidgets('exibe erro ao submeter com senha vazia', (tester) async {
    await pumpPage(tester, RegisterInitial());

    await tester.enterText(find.byType(TextFormField).at(0), 'João Silva');
    await tester.enterText(find.byType(TextFormField).at(1), 'joao@example.com');
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    expect(find.text('Informe a senha.'), findsOneWidget);
  });

  testWidgets('exibe erro de senha fraca quando tem menos de 6 caracteres',
      (tester) async {
    await pumpPage(tester, RegisterInitial());

    await tester.enterText(find.byType(TextFormField).at(0), 'João Silva');
    await tester.enterText(find.byType(TextFormField).at(1), 'joao@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), '123');
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    expect(
        find.text('A senha deve ter pelo menos 6 caracteres.'), findsOneWidget);
  });

  // ── Estado de carregamento ────────────────────────────────────────────────

  testWidgets('exibe CircularProgressIndicator quando estado é RegisterLoading',
      (tester) async {
    await pumpPage(tester, RegisterLoading(), settle: false);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // ── Exibição de erro do BLoC ──────────────────────────────────────────────

  testWidgets('exibe mensagem de erro retornada pelo BLoC', (tester) async {
    await pumpPage(
      tester,
      RegisterError(message: 'auth_error_email_in_use'),
    );

    // "Este e-mail já está cadastrado." é a tradução de auth_error_email_in_use
    expect(find.text('Este e-mail já está cadastrado.'), findsOneWidget);
  });

  // ── Disparo de evento ─────────────────────────────────────────────────────

  testWidgets('dispara RegisterSubmitted ao submeter formulário válido',
      (tester) async {
    final bloc = await pumpPage(tester, RegisterInitial());

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'João Silva');
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump();
    await tester.enterText(fields.at(1), 'joao@example.com');
    await tester.enterText(fields.at(2), '123456');
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    final submitted = bloc.capturedEvents.whereType<RegisterSubmitted>();
    expect(submitted, hasLength(1));
    expect(submitted.first.name, 'João Silva');
    expect(submitted.first.email, 'joao@example.com');
    expect(submitted.first.password, '123456');
    // Apelido sugerido a partir do nome e confirmado como disponível.
    expect(submitted.first.nickname, 'joao');
  });

  // ── Apelido ───────────────────────────────────────────────────────────────

  Future<void> settleNickname(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump();
  }

  String nicknameText(WidgetTester tester) => tester
      .widget<TextField>(find.byKey(NicknameField.fieldKey))
      .controller!
      .text;

  testWidgets('sugere o apelido a partir do nome digitado', (tester) async {
    await pumpPage(tester, RegisterInitial());

    await tester.enterText(find.byType(TextFormField).at(0), 'João Silva');
    await settleNickname(tester);

    expect(nicknameText(tester), 'joao');
    expect(checkNickname.requested, contains('joao'));
    expect(find.text('Boa! @joao está disponível.'), findsOneWidget);
  });

  testWidgets('não sobrescreve o apelido editado pelo usuário', (tester) async {
    await pumpPage(tester, RegisterInitial());

    await tester.enterText(find.byKey(NicknameField.fieldKey), 'Wes Pizetta!');
    await settleNickname(tester);
    // Espaços, maiúsculas e símbolos são filtrados enquanto digita.
    expect(nicknameText(tester), 'wespizetta');

    await tester.enterText(find.byType(TextFormField).at(0), 'Outro Nome');
    await settleNickname(tester);
    expect(nicknameText(tester), 'wespizetta');
  });

  testWidgets('não envia o cadastro quando o apelido está em uso',
      (tester) async {
    final bloc = await pumpPage(
      tester,
      RegisterInitial(),
      nicknameAvailable: false,
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'João Silva');
    await settleNickname(tester);
    await tester.enterText(fields.at(1), 'joao@example.com');
    await tester.enterText(fields.at(2), '123456');
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    expect(find.text('Esse apelido já está em uso.'), findsOneWidget);
    expect(bloc.capturedEvents.whereType<RegisterSubmitted>(), isEmpty);
  });

  testWidgets('exige o apelido ao submeter com o campo vazio', (tester) async {
    final bloc = await pumpPage(tester, RegisterInitial());

    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    expect(find.text('Escolha um apelido.'), findsOneWidget);
    expect(bloc.capturedEvents.whereType<RegisterSubmitted>(), isEmpty);
  });
}
