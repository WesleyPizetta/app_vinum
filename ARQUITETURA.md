# Arquitetura Técnica — app_vinum

## Sumário

- [Visão geral](#visão-geral)
- [Estrutura de pastas](#estrutura-de-pastas)
- [Clean Architecture](#clean-architecture)
  - [Domain](#domain)
  - [Data](#data)
  - [Presentation](#presentation)
  - [Fluxo completo de uma requisição](#fluxo-completo-de-uma-requisição)
- [Injeção de Dependência](#injeção-de-dependência)
  - [ApplicationContainer](#applicationcontainer)
  - [VinumContainer](#vinumcontainer)
  - [Ciclo de vida dos registros](#ciclo-de-vida-dos-registros)
- [Princípios SOLID](#princípios-solid)
- [BLoC — Gerenciamento de Estado](#bloc--gerenciamento-de-estado)
- [Tratamento de erros — Try\<T\>](#tratamento-de-erros--tryt)
- [Comunicação HTTP — Chopper](#comunicação-http--chopper)
- [Autenticação](#autenticação)
- [Pacote Essentials](#pacote-essentials)
- [Ambientes (Dev / Prod)](#ambientes-dev--prod)
- [Navegação](#navegação)
- [Internacionalização](#internacionalização)
- [Tema e Design System](#tema-e-design-system)
- [Diagrama de dependências](#diagrama-de-dependências)

---

## Visão geral

O app_vinum é um aplicativo Flutter organizado em **Clean Architecture** com **BLoC** como gerenciador de estado e **GetIt** como container de injeção de dependência. A separação de responsabilidades é feita em três camadas (Domain, Data, Presentation) dentro de cada feature, com compartilhamento de base via pacote interno `packages/essentials`.

```
┌─────────────────────────────────────────────┐
│              packages/essentials             │  ← biblioteca interna
│  ApplicationContainer · Try<T> · UseCase    │
│  Environment · Widgets · Theme · i18n · API │
└──────────────────┬──────────────────────────┘
                   │ depende de
┌──────────────────▼──────────────────────────┐
│                 lib/ (app)                   │
│                                             │
│  core/          feature/auth/               │
│  ├── di/        ├── domain/                 │
│  ├── navigation/│   ├── entity/             │
│  └── widgets/   │   ├── repository/         │
│                 │   └── usecase/            │
│                 ├── data/                   │
│                 │   ├── api/                │
│                 │   └── repository/         │
│                 └── presentation/           │
│                     ├── bloc/               │
│                     └── page/               │
└─────────────────────────────────────────────┘
```

---

## Estrutura de pastas

```
app_vinum/
├── lib/
│   ├── main.dart              → entrada padrão (aponta para main_dev)
│   ├── main_dev.dart          → bootstrap do ambiente de desenvolvimento
│   ├── main_prod.dart         → bootstrap do ambiente de produção
│   ├── vinum_app.dart         → MaterialApp + rotas + tema + i18n
│   ├── environment/
│   │   ├── environment_dev.dart
│   │   └── environment_prod.dart
│   ├── core/
│   │   ├── di/
│   │   │   └── vinum_container.dart   ← registro de todas as dependências
│   │   ├── navigation/
│   │   │   └── application_route.dart ← constantes de rotas
│   │   └── widgets/
│   │       └── app_version_badge.dart
│   └── feature/
│       ├── auth/              ← login, cadastro, logout
│       ├── wine/              ← listagem e detalhe de vinhos
│       ├── home/              ← tela principal
│       ├── profile/           ← perfil do usuário
│       └── settings/          ← configurações
├── packages/
│   └── essentials/            ← biblioteca interna compartilhada
│       └── lib/
│           ├── base/          ← Try<T>, Failure, UseCase
│           ├── di/            ← ApplicationContainer (wrapper do GetIt)
│           ├── api/           ← createChopperClient, CurlLoggingInterceptor
│           ├── configs/       ← Environment (abstrato)
│           ├── i18n/          ← AppLocalization (JSON-based)
│           └── ui/            ← Theme, Colors, TextStyles, Widgets
├── lang/
│   └── pt_BR.json             ← traduções
└── test/
    └── feature/auth/          ← testes unitários e de widget
```

---

## Clean Architecture

A arquitetura limpa divide cada feature em três camadas com uma regra fundamental:

> **As dependências apontam sempre para dentro.**  
> `Presentation` depende de `Domain`. `Data` depende de `Domain`. `Domain` não depende de nada.

```
┌──────────────────────────────────┐
│         Presentation             │  BLoC, Pages, Widgets
│   conhece Domain, não conhece Data
├──────────────────────────────────┤
│            Domain                │  Entidades, Repositórios (abstratos), UseCases
│   não depende de ninguém        │
├──────────────────────────────────┤
│             Data                 │  Repositórios (concretos), API, Datasources, Models
│   implementa interfaces do Domain
└──────────────────────────────────┘
```

### Domain

É o núcleo da feature. Contém apenas lógica de negócio pura — sem Flutter, sem HTTP, sem banco de dados.

**Entidade:** representa um objeto de negócio real.
```dart
// lib/feature/auth/domain/entity/user.dart
class User {
  final String id;
  final String email;
  final String? name;
  const User({required this.id, required this.email, this.name});
}
```

**Repositório (interface):** contrato que define O QUE pode ser feito, sem dizer COMO.
```dart
// lib/feature/auth/domain/repository/auth_repository.dart
abstract class AuthRepository {
  Future<Try<User>> signIn({required String email, required String password});
  Future<Try<User>> signUp({required String email, required String password, required String name});
  Future<Try<void>> logout();
  User? getCurrentUser();
  // ...
}
```

`Domain` declara essa interface mas não sabe se os dados virão de uma API REST, Supabase, SQLite ou de um mock. Essa decisão é da camada `Data`.

**Caso de uso:** encapsula uma única operação de negócio.
```dart
// lib/feature/auth/domain/usecase/sign_in.dart
class SignIn implements UseCase<User, SignInParams> {
  final AuthRepository _repository;
  SignIn(this._repository);

  @override
  Future<Try<User>> call(SignInParams params) =>
      _repository.signIn(email: params.email, password: params.password);
}
```

Cada caso de uso recebe seus parâmetros via classe dedicada (`SignInParams`, `SignUpParams`), facilitando validação e testabilidade.

Os três contratos base de caso de uso estão em `essentials`:
```dart
abstract class UseCase<T, P>     { Future<Try<T>> call(P params); }
abstract class UnitUseCase<T>    { Future<Try<T>> call(); }
abstract class ObservableUseCase<T, P> { Stream<Try<T>> call(P params); }
```

### Data

Implementa as interfaces do `Domain` e lida com detalhes técnicos de acesso a dados.

**Implementação do repositório:**
```dart
// lib/feature/auth/data/repository/auth_repository_impl.dart
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final AuthApiService _authService;

  @override
  Future<Try<User>> signIn({required String email, required String password}) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email, password: password,
      );
      final user = _toUser(response.user!);
      return Try.success(user);
    } on AuthException catch (e) {
      return Try.reject(KnownFailure(e.statusCode ?? 'AUTH_ERROR', e, message: e.message));
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }
}
```

A camada `Data` também contém:
- **API Service** (`AuthApiService`): interface Chopper declarativa com anotações `@POST`, `@GET`, `@Body`, `@Header`. O código da classe concreta é gerado automaticamente pelo `chopper_generator`.
- **Datasource**: para Wine, existe uma abstração `WineDatasource` com implementações `WineMockDatasource` (ativa agora) e `WineRemoteDatasource` (pronta para quando a API existir).
- **Model**: `WineModel` tem métodos `fromJson`, `toJson`, `toEntity` e `fromEntity` — separa o formato de transferência (JSON da API) da entidade de domínio pura.

### Presentation

A camada de apresentação só se comunica com o `Domain` através de `UseCases` e nunca acessa `Data` diretamente.

```
Page  →  dispara Evento  →  BLoC  →  chama UseCase  →  emite Estado  →  Page se reconstrói
```

**BLoC recebendo caso de uso via construtor:**
```dart
// lib/feature/auth/presentation/bloc/login_bloc.dart
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final SignIn _signIn;
  final AuthRepository _authRepository;

  LoginBloc(this._signIn, this._authRepository) : super(LoginInitial()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    final result = await _signIn(SignInParams(email: event.email, password: event.password));
    result.fold(
      (failure) => emit(LoginError(message: _mapFailureMessage(failure))),
      (user)    => emit(LoginSuccess(user: user)),
    );
  }
}
```

O BLoC não sabe como `SignIn` funciona internamente — só sabe que recebe `SignInParams` e retorna `Try<User>`.

### Fluxo completo de uma requisição

Exemplo: usuário digita e-mail/senha e clica em "Entrar".

```
1. LoginPage detecta tap no botão
        │
        ▼
2. context.read<LoginBloc>().add(LoginSubmitted(email, password))
        │
        ▼
3. LoginBloc._onSubmitted() emite LoginLoading
        │
        ▼
4. LoginBloc chama: _signIn(SignInParams(email, password))
        │
        ▼
5. SignIn.call() chama: _repository.signIn(email, password)
        │
        ▼
6. AuthRepositoryImpl.signIn() chama: Supabase.auth.signInWithPassword()
        │
        ├── sucesso → Try.success(User) → LoginSuccess(user)
        └── erro    → Try.reject(KnownFailure) → LoginError('auth_error_invalid_credentials')
        │
        ▼
7. LoginBloc emite o estado final
        │
        ▼
8. BlocBuilder na LoginPage reconstrói a UI:
   LoginSuccess  → Navigator.pushNamed(ApplicationRoute.home)
   LoginError    → exibe texto do erro traduzido
   LoginLoading  → exibe CircularProgressIndicator
```

---

## Injeção de Dependência

### ApplicationContainer

`ApplicationContainer` é uma fachada fina sobre o `GetIt`, exposta pelo pacote `essentials`:

```dart
// packages/essentials/lib/di/application_container.dart
class ApplicationContainer {
  static final GetIt _getIt = GetIt.instance;

  static T resolve<T extends Object>()                           => _getIt.get<T>();
  static void registerSingleton<T extends Object>(T instance)   => _getIt.registerSingleton<T>(instance);
  static void registerLazySingleton<T extends Object>(factory)  => _getIt.registerLazySingleton<T>(factory);
  static void registerFactory<T extends Object>(factory)        => _getIt.registerFactory<T>(factory);
  static Future<void> reset()                                    => _getIt.reset();
}
```

A fachada tem dois benefícios:
1. **Desacopla o código da lib `get_it`** — se um dia GetIt for trocado por outro container, só `ApplicationContainer` precisa mudar.
2. **Facilita testes** — `ApplicationContainer.reset()` limpa todos os registros entre testes.

### VinumContainer

`VinumContainer.setup()` é chamado uma única vez no `main`, depois do `Supabase.initialize()`. Ele wira toda a árvore de dependências:

```dart
// lib/core/di/vinum_container.dart
class VinumContainer {
  static void setup() {
    // 1. Infraestrutura HTTP
    ApplicationContainer.registerLazySingleton<ChopperClient>(
      () => createChopperClient(
        baseUrl: ApplicationContainer.resolve<Environment>().apiUrl,
        services: [AuthApiService.create()],
      ),
    );

    // 2. API Services
    ApplicationContainer.registerLazySingleton<AuthApiService>(
      () => ApplicationContainer.resolve<ChopperClient>().getService<AuthApiService>(),
    );

    // 3. Repositórios (Data)
    ApplicationContainer.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        authService: ApplicationContainer.resolve<AuthApiService>(),
      ),
    );

    // 4. Casos de uso (Domain)
    ApplicationContainer.registerLazySingleton<SignIn>(
      () => SignIn(ApplicationContainer.resolve<AuthRepository>()),
    );

    // 5. BLoCs (Presentation)
    ApplicationContainer.registerFactory<LoginBloc>(
      () => LoginBloc(
        ApplicationContainer.resolve<SignIn>(),
        ApplicationContainer.resolve<AuthRepository>(),
      ),
    );
    // ...demais BLoCs e dependências de Wine
  }
}
```

A ordem de registro não importa para `registerLazySingleton` — a instância só é criada na primeira chamada de `resolve<T>()`, momento em que todas as dependências já estão registradas.

### Ciclo de vida dos registros

| Método | Comportamento | Quando usar |
|---|---|---|
| `registerSingleton<T>(instance)` | Instância criada na hora, compartilhada globalmente | `Environment` (configurado antes do `setup()`) |
| `registerLazySingleton<T>(factory)` | Instância criada na **primeira** `resolve`, depois reutilizada | `ChopperClient`, repositórios, casos de uso |
| `registerFactory<T>(factory)` | Nova instância a **cada** `resolve` | BLoCs — cada tela deve ter a sua própria instância |

> BLoCs são `registerFactory` por um motivo importante: o BLoC mantém estado interno. Se fosse singleton, ao voltar para a tela de login após um logout, o BLoC ainda teria `LoginSuccess` como estado — o usuário veria a tela já logada.

**Como a Page resolve o BLoC:**
```dart
// lib/feature/auth/presentation/page/login_page.dart
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ApplicationContainer.resolve<LoginBloc>()
        ..add(LoginSessionChecked()),
      child: _LoginView(),
    );
  }
}
```

`BlocProvider.create` chama `resolve<LoginBloc>()`, que executa o factory e retorna uma instância nova. O `..add(LoginSessionChecked())` despacha o evento de verificação de sessão imediatamente.

---

## Princípios SOLID

### S — Single Responsibility (Responsabilidade Única)

Cada classe tem exatamente uma razão para mudar:

| Classe | Única responsabilidade |
|---|---|
| `User` | Representar dados de um usuário |
| `AuthRepository` | Definir o contrato de acesso a dados de auth |
| `AuthRepositoryImpl` | Executar esse contrato usando Supabase + BFF |
| `SignIn` | Executar a operação de login |
| `LoginBloc` | Gerenciar o estado da tela de login |
| `LoginPage` | Renderizar a UI de login |
| `VinumContainer` | Configurar o container de DI |

Nenhuma dessas classes faz mais do que uma coisa. Um `SignIn` não renderiza UI. Um `LoginPage` não faz chamadas HTTP.

### O — Open/Closed (Aberto/Fechado)

Classes são abertas para extensão mas fechadas para modificação. Exemplo com datasource de Wine:

```dart
// Contrato — nunca muda
abstract class WineDatasource {
  Future<List<WineModel>> getWines();
  Future<WineModel> getWineById(String id);
}

// Implementação mock — em uso agora
class WineMockDatasource implements WineDatasource { ... }

// Implementação real — pronta para quando a API existir
class WineRemoteDatasource implements WineDatasource { ... }
```

Para migrar do mock para a API real, basta trocar **um registro** no `VinumContainer`:
```dart
// DE:
ApplicationContainer.registerLazySingleton<WineDatasource>(
  () => WineMockDatasource(),
);

// PARA:
ApplicationContainer.registerLazySingleton<WineDatasource>(
  () => WineRemoteDatasource(ApplicationContainer.resolve<WineApiService>()),
);
```

Nenhum outro arquivo precisa ser modificado. O repositório, os casos de uso e os BLoCs continuam intactos.

### L — Liskov Substitution (Substituição de Liskov)

Qualquer implementação concreta de uma interface pode substituir a abstração sem quebrar o código.

```dart
// WineRepositoryImpl recebe WineDatasource (abstrato)
class WineRepositoryImpl implements WineRepository {
  final WineDatasource _datasource;
  WineRepositoryImpl(this._datasource);
  // funciona com WineMockDatasource OU WineRemoteDatasource indistintamente
}
```

O mesmo princípio se aplica ao `AuthRepository`: `LoginBloc` recebe a interface, não a implementação. Se amanhã Supabase for substituído por Firebase, `LoginBloc` não muda — só `AuthRepositoryImpl` muda.

### I — Interface Segregation (Segregação de Interface)

Interfaces são pequenas e focadas. `AuthRepository` declara apenas os métodos que existem (signIn, signUp, logout, getCurrentUser, etc.). Não há método `getWines` numa interface de auth.

Os contratos de UseCase também são segregados por tipo:
- `UseCase<T, P>` — operação que recebe parâmetros
- `UnitUseCase<T>` — operação sem parâmetros
- `ObservableUseCase<T, P>` — operação que retorna um stream

Um `GetWines` não implementa `UseCase<List<Wine>, Params>` forçando um `Params` vazio — ele implementa `UnitUseCase<List<Wine>>` e o `call()` não recebe argumento.

### D — Dependency Inversion (Inversão de Dependência)

Módulos de alto nível não dependem de módulos de baixo nível — ambos dependem de abstrações.

```
LoginBloc (alto nível)
    depende de → SignIn (abstração de caso de uso)
                     depende de → AuthRepository (abstração de repositório)
                                      implementada por → AuthRepositoryImpl (baixo nível)
```

`LoginBloc` nunca importa `AuthRepositoryImpl`. Ele importa apenas `AuthRepository` (a interface), que vive no `Domain`. `AuthRepositoryImpl` vive no `Data` e é injetado pelo container.

---

## BLoC — Gerenciamento de Estado

O BLoC (Business Logic Component) separa completamente a lógica de negócio da UI:

```
UI  →  add(Evento)  →  BLoC  →  emit(Estado)  →  UI se reconstrói
```

Cada feature de tela tem três arquivos:

- **`*_event.dart`** — o que pode acontecer (ações do usuário ou do sistema)
- **`*_state.dart`** — como a UI deve se apresentar em resposta
- **`*_bloc.dart`** — lógica que transforma eventos em estados

**Exemplo completo — Auth:**

```dart
// Eventos: o que pode ser enviado para o BLoC
abstract class LoginEvent {}
class LoginSessionChecked extends LoginEvent {}              // app abriu
class LoginSubmitted extends LoginEvent { ... }              // usuário clicou em entrar
class LoginSocialSubmitted extends LoginEvent { ... }        // usuário clicou em Google

// Estados: os possíveis estados da tela
abstract class LoginState {}
class LoginInitial extends LoginState {}                     // tela recém aberta
class LoginLoading extends LoginState {}                     // aguardando resposta
class LoginSuccess extends LoginState { final User user; }  // logado
class LoginError extends LoginState { final String message; }// erro
```

A `LoginPage` usa `BlocBuilder` para reconstruir apenas o que muda:

```dart
BlocBuilder<LoginBloc, LoginState>(
  builder: (context, state) {
    if (state is LoginLoading) return const CircularProgressIndicator();
    if (state is LoginError)   return Text(AppLocalization.getString(context, state.message));
    return _LoginForm();
  },
)
```

---

## Tratamento de erros — Try\<T\>

O projeto usa programação funcional para representar resultados que podem falhar, sem exceções escapando para a UI.

`Try<T>` estende `Either<Failure, T>` da lib `dartz`:

```
Try<User>
  ├── Success<User>   → Right — contém o valor
  └── Rejection<User> → Left  — contém um Failure
```

```dart
// Criação
Try.success(user)                           // sucesso
Try.reject(KnownFailure('INVALID', null))   // falha conhecida
Try.reject(UnknownFailure(exception))       // falha inesperada

// Consumo no BLoC usando fold()
result.fold(
  (failure) => emit(LoginError(message: _mapFailureMessage(failure))),
  (user)    => emit(LoginSuccess(user: user)),
);
```

Tipos de falha:
```dart
abstract class Failure { final dynamic error; final String? code; }

class KnownFailure extends Failure {
  final String? message;   // mensagem da API/regra de negócio
  // ex: 'Invalid credentials', 'User already registered'
}

class UnknownFailure extends Failure {
  // qualquer Exception não prevista
}
```

O BLoC mapeia a falha para uma chave de tradução:
```dart
String _mapFailureMessage(Failure failure) {
  if (failure is KnownFailure) {
    final msg = (failure.message ?? '').toLowerCase();
    if (msg.contains('invalid') || msg.contains('credentials'))
      return 'auth_error_invalid_credentials';
    if (msg.contains('email not confirmed'))
      return 'auth_error_email_not_confirmed';
  }
  return 'error_generic';
}
```

A chave `'auth_error_invalid_credentials'` é resolvida por `AppLocalization.getString(context, key)` para `"E-mail ou senha inválidos."` em pt-BR.

---

## Comunicação HTTP — Chopper

O Chopper é um gerador de clientes HTTP type-safe para Dart/Flutter. Você escreve uma interface anotada e o `chopper_generator` gera o código de rede.

**Interface declarada:**
```dart
// lib/feature/auth/data/api/auth_api_service.dart
@ChopperApi(baseUrl: '/v1/auth')
abstract class AuthApiService extends ChopperService {
  @POST(path: '/social/exchange')
  Future<Response<dynamic>> socialExchange(@Body() Map<String, dynamic> body);

  @POST(path: '/logout')
  Future<Response<dynamic>> logout(
    @Body() Map<String, dynamic> body,
    {@Header('Authorization') String? authorization},
  );
}
```

**Cliente configurado no container:**
```dart
ApplicationContainer.registerLazySingleton<ChopperClient>(
  () => createChopperClient(
    baseUrl: ApplicationContainer.resolve<Environment>().apiUrl,
    services: [AuthApiService.create()],
  ),
);
```

`createChopperClient` (de `essentials`) adiciona automaticamente:
- `JsonConverter` — serialização/deserialização automática
- `CurlLoggingInterceptor` — imprime cada requisição como comando `curl` no console de debug

---

## Autenticação

O app usa **duas** formas de autenticação com arquiteturas distintas:

### E-mail e senha

Fluxo direto via **Supabase SDK**:
```
LoginBloc → SignIn → AuthRepositoryImpl → Supabase.auth.signInWithPassword()
```

### Login social (Google)

Fluxo via **BFF** (Backend For Frontend) para não expor secrets no app:
```
LoginBloc → AuthRepositoryImpl.signInWithSocial()
    → Google Sign-In SDK (obtém id_token)
    → POST /v1/auth/social/exchange no BFF (hub_go_etaure)
    → BFF valida o token com o Google e emite JWT próprio
    → app armazena access_token e refresh_token
```

O BFF existe para centralizar a lógica de troca de tokens OAuth sem expor a `client_secret` Google dentro do APK.

---

## Pacote Essentials

`packages/essentials` é uma biblioteca Dart interna ao monorepo. Ela existe para:
1. **Evitar duplicação** de código base (DI, HTTP, tipos funcionais) entre múltiplos módulos.
2. **Impor a API pública**: o app principal só importa `package:essentials/essentials.dart` — um barrel file que re-exporta todas as classes públicas.

Conteúdo exportado:

| Módulo | Classes |
|---|---|
| `base/` | `Try<T>`, `Success`, `Rejection`, `Failure`, `KnownFailure`, `UnknownFailure`, `UseCase`, `UnitUseCase`, `ObservableUseCase` |
| `di/` | `ApplicationContainer` |
| `api/` | `createChopperClient`, `CurlLoggingInterceptor`, re-export de `ChopperClient` |
| `configs/` | `Environment` |
| `i18n/` | `AppLocalizationDelegate`, `AppLocalization`, `GlobalMaterialLocalizations` |
| `ui/` | `VinumTheme`, `VinumPalette`, `AppTheme`, `Dimens`, `VinumTextStyles`, `VinumAppBar`, `PrimaryButton`, `SecondaryButton`, `LoadingWidget`, `VinumErrorWidget` |

---

## Ambientes (Dev / Prod)

O app tem dois entry points — `main_dev.dart` e `main_prod.dart` — que configuram diferentes implementações de `Environment`:

```dart
// lib/environment/environment_dev.dart
class DevEnvironment extends Environment {
  DevEnvironment({String? apiUrl, String? googleWebClientId})
      : super(
          isProduction: false,
          apiUrl: apiUrl ?? 'http://10.0.2.2:8080',  // localhost do emulador Android
          name: 'DEV',
          googleWebClientId: googleWebClientId ?? '',
        );
}
```

```dart
// lib/environment/environment_prod.dart
class ProdEnvironment extends Environment {
  ProdEnvironment({String? apiUrl, String? googleWebClientId})
      : super(
          isProduction: true,
          apiUrl: apiUrl ?? 'https://api.vinum.com',
          name: 'PROD',
          googleWebClientId: googleWebClientId ?? '',
        );
}
```

As URLs e chaves vêm do arquivo `.env` via `flutter_dotenv`. O `Environment` é registrado **antes** de `VinumContainer.setup()`, para que o `ChopperClient` consiga resolver `apiUrl` ao ser criado.

```dart
// main_dev.dart
await dotenv.load(fileName: '.env');
await Supabase.initialize(url: dotenv.env['SUPABASE_URL']!, ...);

// 1. Registra o ambiente PRIMEIRO
ApplicationContainer.registerSingleton<Environment>(
  DevEnvironment(apiUrl: dotenv.env['BFF_API_URL']),
);

// 2. Wira o restante (que depende do Environment)
VinumContainer.setup();

runApp(const VinumApp());
```

---

## Navegação

O app usa o sistema de rotas nomeadas padrão do Flutter (`MaterialApp.routes`), com constantes centralizadas:

```dart
// lib/core/navigation/application_route.dart
class ApplicationRoute {
  static const String login    = '/login';
  static const String register = '/register';
  static const String home     = '/';
  static const String settings = '/settings';
  static const String wineList = '/wines';
  static const String wineDetail = '/wines/detail';
  static const String me       = '/me';
}
```

```dart
// lib/vinum_app.dart
MaterialApp(
  initialRoute: ApplicationRoute.login,
  routes: {
    ApplicationRoute.login:    (_) => const LoginPage(),
    ApplicationRoute.register: (_) => const RegisterPage(),
    ApplicationRoute.home:     (_) => const HomePage(),
    // ...
  },
)
```

Navegação nos BLoCs/Pages via `Navigator.pushReplacementNamed(context, ApplicationRoute.home)`.

---

## Internacionalização

O sistema de i18n carrega arquivos JSON de `lang/` em vez de usar o ARB padrão do Flutter:

```
lang/
└── pt_BR.json
```

```json
{
  "auth_error_invalid_credentials": "E-mail ou senha inválidos.",
  "auth_error_email_not_confirmed": "Confirme seu e-mail antes de entrar.",
  "auth_error_email_in_use": "Este e-mail já está cadastrado.",
  "auth_error_weak_password": "A senha deve ter pelo menos 6 caracteres.",
  "error_generic": "Ocorreu um erro. Tente novamente."
}
```

**Resolução de string:**
```dart
// Em qualquer Widget com contexto
AppLocalization.getString(context, 'auth_error_invalid_credentials')
// → "E-mail ou senha inválidos."
```

O `AppLocalizationDelegate` implementa `LocalizationsDelegate<AppLocalization>` e carrega o arquivo correto baseado no locale ativo. Isso é o mesmo mecanismo que `GlobalMaterialLocalizations` usa — por isso precisamos registrá-lo no `localizationsDelegates` do `MaterialApp`.

---

## Tema e Design System

O design system está completamente encapsulado em `essentials/ui/`:

```dart
// packages/essentials/lib/ui/app_theme.dart
class VinumTheme {
  final VinumPalette palette;
  VinumTheme(this.palette);

  ThemeData get themeData => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: palette.primary, ...),
    textTheme: VinumTextStyles.textTheme,
    // ...
  );
}
```

**Paleta** (Art Nouveau / vínico):
- Rose Gold: `#C4956A`
- Burgundy: `#722F37`
- Cream: `#FAF3E0`
- Gold: `#D4AF37`
- Deep Wine: `#4A0E17`

**Tipografia:** fontes customizadas `Amarante` (display/títulos) e `Caveat` (cursiva/destaques) carregadas de `fonts/`.

**Widgets do design system:**
- `PrimaryButton` — `ElevatedButton` estilizado
- `SecondaryButton` — `OutlinedButton` estilizado
- `VinumAppBar` — `AppBar` com título em Amarante
- `LoadingWidget` — `CircularProgressIndicator` centralizado
- `VinumErrorWidget` — card de erro com ícone e mensagem

---

## Diagrama de dependências

```
main_dev.dart / main_prod.dart
    │
    ├── Supabase.initialize()
    ├── ApplicationContainer.registerSingleton<Environment>(DevEnvironment)
    └── VinumContainer.setup()
            │
            ├── ChopperClient ←─────────────────── Environment.apiUrl
            ├── AuthApiService ←──────────────────── ChopperClient
            ├── AuthRepository ←──────────────────── AuthApiService
            │       │
            │       ▲ implementado por AuthRepositoryImpl
            │
            ├── SignIn ←──────────────── AuthRepository
            ├── SignUp ←──────────────── AuthRepository
            ├── Logout ←──────────────── AuthRepository
            │
            ├── LoginBloc ←────────────── SignIn + AuthRepository
            ├── RegisterBloc ←─────────── SignUp
            ├── ProfileBloc ←─────────── AuthRepository + Logout
            │
            ├── WineDatasource ←────────── WineMockDatasource
            ├── WineRepository ←────────── WineDatasource
            ├── GetWines ←──────────────── WineRepository
            ├── GetWineById ←───────────── WineRepository
            ├── WineListBloc ←──────────── GetWines
            ├── WineDetailBloc ←────────── GetWineById
            └── HomeBloc ←──────────────── AuthRepository
```

```
VinumApp (MaterialApp)
    │
    └── routes
         ├── LoginPage    → BlocProvider<LoginBloc>
         ├── RegisterPage → BlocProvider<RegisterBloc>
         ├── HomePage     → BlocProvider<HomeBloc>
         ├── WineListPage → BlocProvider<WineListBloc>
         ├── WineDetailPage → BlocProvider<WineDetailBloc>
         └── ProfilePage  → BlocProvider<ProfileBloc>
```

Cada `BlocProvider` chama `ApplicationContainer.resolve<XBloc>()` que retorna uma instância nova via `registerFactory` — garantindo estado limpo por tela.
