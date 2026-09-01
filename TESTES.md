# Guia de Testes — app_vinum

## Sumário

- [Por que testar?](#por-que-testar)
- [Tipos de teste que usamos](#tipos-de-teste-que-usamos)
- [Pacotes utilizados](#pacotes-utilizados)
- [Estrutura dos arquivos](#estrutura-dos-arquivos)
- [Testes unitários de BLoC](#testes-unitários-de-bloc)
  - [Como o BLoC funciona](#como-o-bloc-funciona)
  - [login\_bloc\_test.dart](#login_bloc_testdart)
  - [register\_bloc\_test.dart](#register_bloc_testdart)
- [Testes de widget](#testes-de-widget)
  - [Como o widget test funciona](#como-o-widget-test-funciona)
  - [login\_page\_test.dart](#login_page_testdart)
  - [register\_page\_test.dart](#register_page_testdart)
- [Conceitos e técnicas aplicadas](#conceitos-e-técnicas-aplicadas)
- [Como executar os testes](#como-executar-os-testes)
- [Resultado final](#resultado-final)

---

## Por que testar?

Testes automatizados garantem que o comportamento do código continua correto após mudanças. Em vez de abrir o app e navegar manualmente até a tela de login para verificar se a validação funciona, você executa um comando e recebe a confirmação em segundos — sem emulador, sem interação humana.

No contexto deste projeto, os testes cobrem duas camadas:

1. **Lógica de negócio** — o BLoC que decide o que acontece quando o usuário clica em "entrar".
2. **Interface** — a tela que renderiza os campos, exibe erros e dispara os eventos corretos.

---

## Tipos de teste que usamos

| Tipo | O que testa | Velocidade |
|---|---|---|
| **Teste unitário** | Uma classe ou função isolada, sem UI | Muito rápido |
| **Teste de widget** | A árvore de widgets renderizada virtualmente | Rápido (sem emulador) |
| **Teste de integração** | O app completo em um dispositivo real | Lento |

Criamos testes unitários e de widget. Testes de integração não foram necessários aqui.

---

## Pacotes utilizados

```yaml
# pubspec.yaml — dev_dependencies
flutter_test:         # SDK do Flutter, base de todos os testes
bloc_test: ^10.0.0    # Utilitários para testar BLoCs (blocTest)
mocktail: ^1.0.0      # Criação de mocks e fakes sem geração de código
```

### flutter_test
Fornece as funções fundamentais: `test()`, `testWidgets()`, `expect()`, `find`, `setUp`, `tearDown`. Já vem incluído no SDK do Flutter.

### bloc_test
Adiciona a função `blocTest<BloC, State>()`, que cria e executa um BLoC de forma controlada: você fornece os eventos e declara exatamente quais estados espera receber na ordem certa.

### mocktail
Permite criar **mocks** (substitutos falsos) de dependências como `SignIn` e `AuthRepository` sem precisar de geração de código (`build_runner`). Com `when(...).thenAnswer(...)` você dita o retorno de qualquer método.

---

## Estrutura dos arquivos

```
test/
└── feature/
    └── auth/
        ├── bloc/
        │   ├── login_bloc_test.dart    ← testes unitários do LoginBloc
        │   └── register_bloc_test.dart ← testes unitários do RegisterBloc
        └── page/
            ├── login_page_test.dart    ← testes de widget da LoginPage
            └── register_page_test.dart ← testes de widget da RegisterPage
```

A estrutura espelha `lib/feature/auth/` para facilitar a navegação.

---

## Testes unitários de BLoC

### Como o BLoC funciona

O padrão BLoC (Business Logic Component) separa a lógica da UI:

```
UI  →  add(Evento)  →  [BLoC]  →  emit(Estado)  →  UI se reconstrói
```

- **Evento**: algo que o usuário fez (`LoginSubmitted`, `RegisterSubmitted`).
- **Estado**: o resultado que a UI deve exibir (`LoginLoading`, `LoginSuccess`, `LoginError`).
- **BLoC**: recebe o evento, chama casos de uso (como `SignIn`), e emite estados.

Os testes unitários verificam exatamente essa sequência — dado um tipo específico de evento e um retorno específico do repositório, quais estados são emitidos e em que ordem.

---

### login_bloc_test.dart

**Arquivo:** [test/feature/auth/bloc/login_bloc_test.dart](test/feature/auth/bloc/login_bloc_test.dart)

#### Mocks declarados

```dart
class MockSignIn extends Mock implements SignIn {}
class MockAuthRepository extends Mock implements AuthRepository {}
```

`MockSignIn` é o substituto falso do caso de uso de login. `MockAuthRepository` é o substituto do repositório. Nenhuma chamada real à API ou banco de dados acontece.

```dart
const _tUser = User(id: '1', email: 'test@example.com', name: 'Test User');
```

Objeto de usuário fixo reutilizado em todos os testes de sucesso.

#### setUp / setUpAll

```dart
setUpAll(() {
  registerFallbackValue(const SignInParams(email: '', password: ''));
});
setUp(() {
  mockSignIn = MockSignIn();
  mockAuthRepository = MockAuthRepository();
});
```

- `setUpAll`: roda uma vez antes de todos os testes. `registerFallbackValue` é exigência do mocktail — permite usar `any()` como matcher para tipos customizados como `SignInParams`.
- `setUp`: roda antes de **cada** teste. Recria os mocks limpos para garantir que um teste não afete o próximo.

#### Grupo: `LoginSessionChecked`

Evento disparado automaticamente ao abrir o app, verificando se já existe uma sessão ativa.

| Teste | Cenário | Estado esperado |
|---|---|---|
| `emits [LoginSuccess] quando já existe sessão ativa` | `getCurrentUser()` retorna um usuário | `[LoginSuccess]` |
| `não emite nada quando não há sessão ativa` | `getCurrentUser()` retorna `null` | `[]` (lista vazia) |

```dart
blocTest<LoginBloc, LoginState>(
  'emits [LoginSuccess] quando já existe sessão ativa',
  build: () {
    when(() => mockAuthRepository.getCurrentUser()).thenReturn(_tUser);
    return LoginBloc(mockSignIn, mockAuthRepository);
  },
  act: (bloc) => bloc.add(LoginSessionChecked()),
  expect: () => [
    isA<LoginSuccess>().having((s) => s.user.email, 'email', _tUser.email),
  ],
);
```

- `build`: constrói o BLoC com as dependências mockadas.
- `act`: dispara o evento.
- `expect`: declara a lista de estados emitidos. `isA<LoginSuccess>()` verifica o tipo; `.having(...)` verifica um campo específico dentro do estado.

#### Grupo: `LoginSubmitted`

Evento gerado quando o usuário preenche e-mail e senha e clica em "entrar".

| Teste | Cenário | Estados esperados |
|---|---|---|
| sucesso | `signIn` retorna `Try.success(_tUser)` | `[LoginLoading, LoginSuccess]` |
| credenciais inválidas | `signIn` retorna `KnownFailure` com "Invalid credentials" | `[LoginLoading, LoginError(auth_error_invalid_credentials)]` |
| e-mail não confirmado | `signIn` retorna `KnownFailure` com "Email not confirmed" | `[LoginLoading, LoginError(auth_error_email_not_confirmed)]` |
| falha desconhecida | `signIn` retorna `UnknownFailure` | `[LoginLoading, LoginError(error_generic)]` |

O BLoC sempre emite `LoginLoading` primeiro, mostrando o indicador de carregamento, e depois o estado final. O tipo de `KnownFailure` determina qual chave de tradução o `LoginError` carrega.

#### Grupo: `LoginSocialSubmitted`

Evento de login via Google.

| Teste | Estados esperados |
|---|---|
| login social bem-sucedido | `[LoginLoading, LoginSuccess]` |
| falha no token social | `[LoginLoading, LoginError]` |

---

### register_bloc_test.dart

**Arquivo:** [test/feature/auth/bloc/register_bloc_test.dart](test/feature/auth/bloc/register_bloc_test.dart)

#### Mock declarado

```dart
class MockSignUp extends Mock implements SignUp {}
```

O `RegisterBloc` depende apenas do caso de uso `SignUp`.

#### Grupo: `RegisterSubmitted`

Evento disparado quando o usuário preenche nome, e-mail, senha e clica em "cadastrar".

| Teste | Cenário | Estados esperados |
|---|---|---|
| sucesso | `signUp` retorna `Try.success(_tUser)` | `[RegisterLoading, RegisterSuccess]` |
| e-mail já cadastrado | `KnownFailure` com "User already registered" | `[RegisterLoading, RegisterError(auth_error_email_in_use)]` |
| senha fraca | `KnownFailure` com "Password should be at least 6 characters" | `[RegisterLoading, RegisterError(auth_error_weak_password)]` |
| falha genérica | `UnknownFailure` | `[RegisterLoading, RegisterError(error_generic)]` |

---

## Testes de widget

### Como o widget test funciona

O Flutter fornece um motor de renderização virtual. Sem emulador ou dispositivo físico, é possível construir uma árvore de widgets completa na memória e interagir com ela programaticamente.

```dart
testWidgets('descrição do teste', (WidgetTester tester) async {
  // 1. Renderiza o widget
  await tester.pumpWidget(MinhaPage());

  // 2. Interage (opcional)
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump(); // executa um frame após a interação

  // 3. Verifica
  expect(find.text('Erro'), findsOneWidget);
});
```

#### Finders

`find` localiza widgets na árvore:

| Finder | O que localiza |
|---|---|
| `find.byType(TextFormField)` | Widgets pelo tipo Dart |
| `find.text('Informe o e-mail.')` | Widgets que exibem um texto exato |
| `find.byType(ElevatedButton).first` | Primeiro widget do tipo |
| `find.byType(TextFormField).at(1)` | Widget pelo índice |

#### Matchers

`expect(finder, matcher)` verifica o resultado:

| Matcher | Significado |
|---|---|
| `findsOneWidget` | Exatamente 1 widget encontrado |
| `findsNWidgets(3)` | Exatamente N widgets encontrados |
| `findsWidgets` | 1 ou mais widgets encontrados |

#### pump e pumpAndSettle

| Método | Quando usar |
|---|---|
| `tester.pump()` | Executa exatamente **um frame** — ideal após interações, ou quando há animações infinitas |
| `tester.pumpAndSettle()` | Executa frames até a UI parar de animar — não funciona com `CircularProgressIndicator` (que anima para sempre) |
| `tester.runAsync(fn)` | Permite que código assíncrono **real** (I/O) seja executado — necessário quando o widget carrega assets |

---

### login_page_test.dart

**Arquivo:** [test/feature/auth/page/login_page_test.dart](test/feature/auth/page/login_page_test.dart)

#### _FakeLoginBloc

```dart
class _FakeLoginBloc extends Bloc<LoginEvent, LoginState>
    implements LoginBloc {
  final capturedEvents = <LoginEvent>[];

  _FakeLoginBloc(super.initialState) {
    on<LoginSessionChecked>((e, _) => capturedEvents.add(e));
    on<LoginSubmitted>((e, _) => capturedEvents.add(e));
    on<LoginSocialSubmitted>((e, _) => capturedEvents.add(e));
  }
}
```

Um BLoC **real** (não um mock) que aceita um estado inicial fixo e não emite nada ao receber eventos — apenas os armazena em `capturedEvents` para verificação posterior. Isso garante que a `LoginPage`, que usa `BlocBuilder`, renderize corretamente com o estado que queremos testar.

#### _FakeEnvironment

```dart
class _FakeEnvironment extends Fake implements Environment {
  @override
  bool get isProduction => false;
  // ...
}
```

O widget `AppVersionBadge` dentro da `LoginPage` resolve `Environment` do container de DI. Este fake satisfaz essa dependência sem registrar configurações reais.

#### pumpPage

```dart
Future<_FakeLoginBloc> pumpPage(
  WidgetTester tester,
  LoginState initialState, {
  bool settle = true,
}) async {
  final bloc = _FakeLoginBloc(initialState);

  // 1. Reseta o container de DI (GetIt) entre testes
  await ApplicationContainer.reset();
  ApplicationContainer.registerFactory<LoginBloc>(() => bloc);
  ApplicationContainer.registerSingleton<Environment>(_FakeEnvironment());

  // 2. Limpa a árvore de widgets anterior
  await tester.pumpWidget(const SizedBox.shrink());

  // 3. Constrói a página dentro de runAsync para permitir I/O real
  //    (carregamento do arquivo de localização lang/pt_BR.json)
  await tester.runAsync(() async {
    await tester.pumpWidget(_buildApp(LoginPage(key: UniqueKey())));
  });

  // 4. Aguarda a UI estabilizar (ou apenas um frame para estados com loading)
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }

  return bloc;
}
```

Esta função centraliza toda a montagem da tela para que cada `testWidgets` seja limpo e conciso. O parâmetro `settle: false` existe porque o `CircularProgressIndicator` (exibido em `LoginLoading`) anima infinitamente — chamar `pumpAndSettle()` causaria timeout.

#### `_buildApp`

```dart
Widget _buildApp(Widget home) => MaterialApp(
  localizationsDelegates: [
    AppLocalizationDelegate(supportedLocales: const [Locale('pt', 'BR')]),
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: const [Locale('pt', 'BR')],
  locale: const Locale('pt', 'BR'),
  // ...
  home: home,
);
```

Envolve a página num `MaterialApp` mínimo com suporte a localização em pt-BR, permitindo que textos como `'Informe o e-mail.'` sejam resolvidos corretamente a partir do arquivo `lang/pt_BR.json`.

#### Testes da LoginPage

| # | Teste | O que verifica |
|---|---|---|
| 1 | `exibe campos de e-mail e senha` | A página renderiza 2 `TextFormField` e pelo menos 1 `ElevatedButton` |
| 2 | `exibe erro ao submeter com e-mail vazio` | Clicar no botão sem preencher nada exibe `'Informe o e-mail.'` |
| 3 | `exibe erro ao submeter com senha vazia` | Preencher só o e-mail e clicar exibe `'Informe a senha.'` |
| 4 | `exibe CircularProgressIndicator quando estado é LoginLoading` | Com estado `LoginLoading`, aparece o indicador de carregamento |
| 5 | `exibe mensagem de erro retornada pelo BLoC` | Com estado `LoginError('auth_error_invalid_credentials')`, exibe `'E-mail ou senha inválidos.'` |
| 6 | `dispara LoginSubmitted ao submeter formulário válido` | Preencher e-mail + senha e clicar faz o BLoC capturar um `LoginSubmitted` com os valores corretos |
| 7 | `exibe botão de link para criar conta` | Existe pelo menos um `TextButton` na tela (o link "Criar conta") |

---

### register_page_test.dart

**Arquivo:** [test/feature/auth/page/register_page_test.dart](test/feature/auth/page/register_page_test.dart)

A estrutura é idêntica à da `LoginPage`. A diferença são os 3 campos (nome, e-mail, senha) e o `RegisterBloc`.

#### _FakeRegisterBloc

```dart
class _FakeRegisterBloc extends Bloc<RegisterEvent, RegisterState>
    implements RegisterBloc {
  final capturedEvents = <RegisterEvent>[];

  _FakeRegisterBloc(super.initialState) {
    on<RegisterSubmitted>((e, _) => capturedEvents.add(e));
  }
}
```

Captura `RegisterSubmitted` sem emitir estados.

#### Testes da RegisterPage

| # | Teste | O que verifica |
|---|---|---|
| 1 | `exibe campos de nome, e-mail e senha` | A página renderiza 3 `TextFormField` |
| 2 | `exibe erro ao submeter com nome vazio` | Clicar sem preencher nada exibe `'Informe o nome.'` |
| 3 | `exibe erro ao submeter com e-mail vazio` | Preencher só o nome exibe `'Informe o e-mail.'` |
| 4 | `exibe erro ao submeter com senha vazia` | Nome + e-mail preenchidos, senha vazia exibe `'Informe a senha.'` |
| 5 | `exibe erro de senha fraca quando tem menos de 6 caracteres` | Senha com 3 caracteres exibe `'A senha deve ter pelo menos 6 caracteres.'` |
| 6 | `exibe CircularProgressIndicator quando estado é RegisterLoading` | Estado `RegisterLoading` exibe o indicador de carregamento |
| 7 | `exibe mensagem de erro retornada pelo BLoC` | Estado `RegisterError('auth_error_email_in_use')` exibe `'Este e-mail já está cadastrado.'` |
| 8 | `dispara RegisterSubmitted ao submeter formulário válido` | Formulário válido faz o BLoC capturar `RegisterSubmitted` com nome, e-mail e senha corretos |

---

## Conceitos e técnicas aplicadas

### Try\<T\>

O projeto usa um tipo funcional `Try<T>` (semelhante a `Either` do Haskell/dartz):

```
Try.success(valor)  →  caminho feliz
Try.reject(failure) →  caminho de erro
```

Nos testes de BLoC, o mock retorna `Try.success(user)` para simular sucesso ou `Try.reject(KnownFailure(...))` para simular falhas previstas.

### KnownFailure vs UnknownFailure

| Tipo | Quando ocorre | Resultado no BLoC |
|---|---|---|
| `KnownFailure` | Erro de negócio esperado (credenciais inválidas, e-mail duplicado) | `LoginError` com chave de tradução específica |
| `UnknownFailure` | Erro técnico inesperado (timeout, crash de rede) | `LoginError` com chave genérica `error_generic` |

### ApplicationContainer / GetIt

O app usa injeção de dependência via `GetIt` encapsulado em `ApplicationContainer`. Nos testes, chamamos `ApplicationContainer.reset()` antes de cada teste e registramos as dependências falsas:

```dart
ApplicationContainer.registerFactory<LoginBloc>(() => bloc);
ApplicationContainer.registerSingleton<Environment>(_FakeEnvironment());
```

Isso isola cada teste — nenhum estado compartilhado entre eles.

### tester.runAsync

O sistema de teste do Flutter usa **FakeAsync**: um relógio virtual que controla `Future`, `Timer` e `Stream` sem depender do tempo real. Isso torna os testes rápidos e determinísticos.

O problema é que I/O real (leitura de arquivos) não passa por esse relógio virtual. A `AppLocalizationDelegate` carrega o arquivo `lang/pt_BR.json` do disco, e o `AppVersionBadge` chama `PackageInfo.fromPlatform()`. Sem `runAsync`, o FakeAsync encerra antes desses resultados chegarem, deixando a árvore de widgets incompleta nos testes seguintes.

```dart
await tester.runAsync(() async {
  await tester.pumpWidget(_buildApp(LoginPage(key: UniqueKey())));
});
```

`runAsync` "sai" do FakeAsync e permite que I/O real seja concluído antes de continuar.

### settle: false para CircularProgressIndicator

O `CircularProgressIndicator` do Material Design é uma animação que roda indefinidamente. Chamar `pumpAndSettle()` nesse cenário faria Flutter girar frames para sempre até estourar o timeout (padrão: 100 tentativas × 100ms = 10 segundos).

A solução é usar `pump()` no lugar — ele executa apenas um frame, o suficiente para verificar que o widget existe na árvore:

```dart
// pumpPage com settle: false → chama pump() em vez de pumpAndSettle()
await pumpPage(tester, LoginLoading(), settle: false);
expect(find.byType(CircularProgressIndicator), findsOneWidget);
```

---

## Como executar os testes

```bash
# Todos os testes de auth
flutter test test/feature/auth/

# Apenas BLoC
flutter test test/feature/auth/bloc/

# Apenas widgets
flutter test test/feature/auth/page/

# Um arquivo específico
flutter test test/feature/auth/bloc/login_bloc_test.dart

# Com saída detalhada (nome de cada teste)
flutter test test/feature/auth/ --reporter=expanded
```

---

## Resultado final

```
+27: All tests passed!
```

| Arquivo | Testes | Tipo |
|---|---|---|
| `login_bloc_test.dart` | 8 | Unitário (BLoC) |
| `register_bloc_test.dart` | 4 | Unitário (BLoC) |
| `login_page_test.dart` | 7 | Widget |
| `register_page_test.dart` | 8 | Widget |
| **Total** | **27** | |
