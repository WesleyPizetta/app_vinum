import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vinum/feature/auth/presentation/bloc/login_bloc.dart';
import 'package:vinum/feature/auth/presentation/bloc/login_event.dart';
import 'package:vinum/feature/auth/presentation/bloc/login_state.dart';
import 'package:vinum/feature/auth/presentation/page/login_page.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

/// Bloc falso que captura eventos sem alterar estado, útil para widget tests.
class _FakeLoginBloc extends Bloc<LoginEvent, LoginState>
    implements LoginBloc {
  final capturedEvents = <LoginEvent>[];

  _FakeLoginBloc(super.initialState) {
    on<LoginSessionChecked>((e, _) => capturedEvents.add(e));
    on<LoginSubmitted>((e, _) => capturedEvents.add(e));
    on<LoginSocialSubmitted>((e, _) => capturedEvents.add(e));
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

  Future<_FakeLoginBloc> pumpPage(
    WidgetTester tester,
    LoginState initialState, {
    bool settle = true,
  }) async {
    final bloc = _FakeLoginBloc(initialState);
    await ApplicationContainer.reset();
    ApplicationContainer.registerFactory<LoginBloc>(() => bloc);
    ApplicationContainer.registerSingleton<Environment>(_FakeEnvironment());

    await tester.pumpWidget(const SizedBox.shrink());

    await tester.runAsync(() async {
      await tester.pumpWidget(_buildApp(LoginPage(key: UniqueKey())));
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

  testWidgets('exibe campos de e-mail e senha', (tester) async {
    await pumpPage(tester, LoginInitial());

    expect(find.byType(TextFormField), findsNWidgets(2));
    // Verifica se PrimaryButton (ElevatedButton) também está na árvore
    expect(find.byType(ElevatedButton), findsWidgets);
  });

  // ── Validação de formulário ───────────────────────────────────────────────

  testWidgets('exibe erro ao submeter com e-mail vazio', (tester) async {
    await pumpPage(tester, LoginInitial());

    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    expect(find.text('Informe o e-mail.'), findsOneWidget);
  });

  testWidgets('exibe erro ao submeter com senha vazia', (tester) async {
    await pumpPage(tester, LoginInitial());

    await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    expect(find.text('Informe a senha.'), findsOneWidget);
  });

  // ── Estado de carregamento ────────────────────────────────────────────────

  testWidgets('exibe CircularProgressIndicator quando estado é LoginLoading',
      (tester) async {
    await pumpPage(tester, LoginLoading(), settle: false);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // ── Exibição de erro do BLoC ──────────────────────────────────────────────

  testWidgets('exibe mensagem de erro retornada pelo BLoC', (tester) async {
    await pumpPage(
      tester,
      LoginError(message: 'auth_error_invalid_credentials'),
    );

    expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);
  });

  // ── Disparo de evento ─────────────────────────────────────────────────────

  testWidgets('dispara LoginSubmitted ao submeter formulário válido',
      (tester) async {
    final bloc = await pumpPage(tester, LoginInitial());

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'test@example.com');
    await tester.enterText(fields.at(1), '123456');
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    final submitted = bloc.capturedEvents.whereType<LoginSubmitted>();
    expect(submitted, hasLength(1));
    expect(submitted.first.email, 'test@example.com');
    expect(submitted.first.password, '123456');
  });

  // ── Navegação para cadastro ───────────────────────────────────────────────

  testWidgets('exibe botão de link para criar conta', (tester) async {
    await pumpPage(tester, LoginInitial());

    expect(find.byType(TextButton), findsWidgets);
  });
}
