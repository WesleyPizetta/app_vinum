import 'dart:async';
import 'dart:convert';

import 'package:essentials/essentials.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../api/auth_api_service.dart';
import '../../../../core/utils/json_utils.dart';
import '../model/onboarding_question_model.dart';
import '../model/onboarding_result_model.dart';
import '../../../profile/data/api/profile_api_service.dart';
import '../../domain/entity/onboarding_failure_code.dart';
import '../../domain/entity/onboarding_question.dart';
import '../../domain/entity/onboarding_result.dart';
import '../../domain/entity/sign_up_result.dart';
import '../../domain/entity/user.dart';
import '../../domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthApiService authService,
    required ProfileApiService profileService,
    FlutterSecureStorage? secureStorage,
    supa.SupabaseClient? supabaseClient,
  })  : _authService = authService,
        _profileService = profileService,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _customClient = supabaseClient {
    _restoreFuture = _initPersistence();
  }

  /// Restauração assíncrona iniciada no construtor. [restoreSession] a
  /// aguarda para não decidir a rota inicial com dados incompletos.
  late final Future<void> _restoreFuture;

  /// Limite para buscar o perfil na abertura (o Render pode demorar a
  /// "acordar"). Estourado, usamos o que está salvo no aparelho.
  static const Duration _profileRefreshTimeout = Duration(seconds: 8);

  final AuthApiService _authService;
  final ProfileApiService _profileService;
  final supa.SupabaseClient? _customClient;
  final FlutterSecureStorage _secureStorage;

  supa.SupabaseClient get _client =>
      _customClient ?? supa.Supabase.instance.client;

  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;

  Future<void> _initPersistence() async {
    await _restoreLocalSession();
  }

  Future<void> _restoreLocalSession() async {
    try {
      final token = await _secureStorage.read(key: 'auth_access_token');
      final refresh = await _secureStorage.read(key: 'auth_refresh_token');
      _accessToken ??= _normalizeToken(token);
      _refreshToken ??= refresh;

      final id = await _secureStorage.read(key: 'auth_user_id');
      final storedOnboarding = _readBool(await _secureStorage.read(
            key: 'auth_user_onboarding_completed',
          )) ??
          false;

      // O usuário pode ter sido criado antes a partir da sessão do Supabase
      // (sem o flag de onboarding). Não perde o "onboarding concluído" salvo.
      final existing = _currentUser;
      if (existing != null &&
          existing.id == id &&
          storedOnboarding &&
          !existing.onboardingCompleted) {
        _currentUser = existing.copyWith(onboardingCompleted: true);
      }

      if (_currentUser == null) {
        final email = await _secureStorage.read(key: 'auth_user_email');
        if (id != null && id.isNotEmpty && email != null) {
          final name = await _secureStorage.read(key: 'auth_user_name');
          final avatar = await _secureStorage.read(key: 'auth_user_avatar_url');
          _currentUser = User(
            id: id,
            email: email,
            name: name,
            avatarUrl: avatar,
            onboardingCompleted: storedOnboarding,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthRepository] Erro ao restaurar sessão segura: $e');
      }
    }
  }

  Future<void> _saveLocalSession() async {
    try {
      if (_accessToken != null) {
        await _secureStorage.write(
            key: 'auth_access_token', value: _accessToken!);
      } else {
        await _secureStorage.delete(key: 'auth_access_token');
      }

      if (_refreshToken != null) {
        await _secureStorage.write(
            key: 'auth_refresh_token', value: _refreshToken!);
      } else {
        await _secureStorage.delete(key: 'auth_refresh_token');
      }

      if (_currentUser != null) {
        await _secureStorage.write(
            key: 'auth_user_id', value: _currentUser!.id);
        await _secureStorage.write(
            key: 'auth_user_email', value: _currentUser!.email);
        if (_currentUser!.name != null) {
          await _secureStorage.write(
              key: 'auth_user_name', value: _currentUser!.name!);
        } else {
          await _secureStorage.delete(key: 'auth_user_name');
        }
        if (_currentUser!.avatarUrl != null) {
          await _secureStorage.write(
              key: 'auth_user_avatar_url', value: _currentUser!.avatarUrl!);
        } else {
          await _secureStorage.delete(key: 'auth_user_avatar_url');
        }
        await _secureStorage.write(
          key: 'auth_user_onboarding_completed',
          value: _currentUser!.onboardingCompleted.toString(),
        );
      } else {
        await _secureStorage.delete(key: 'auth_user_id');
        await _secureStorage.delete(key: 'auth_user_email');
        await _secureStorage.delete(key: 'auth_user_name');
        await _secureStorage.delete(key: 'auth_user_avatar_url');
        await _secureStorage.delete(key: 'auth_user_onboarding_completed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthRepository] Erro ao salvar sessão segura: $e');
      }
    }
  }

  Future<void> _clearLocalSession() async {
    try {
      await _secureStorage.delete(key: 'auth_access_token');
      await _secureStorage.delete(key: 'auth_refresh_token');
      await _secureStorage.delete(key: 'auth_user_id');
      await _secureStorage.delete(key: 'auth_user_email');
      await _secureStorage.delete(key: 'auth_user_name');
      await _secureStorage.delete(key: 'auth_user_avatar_url');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthRepository] Erro ao limpar sessão segura: $e');
      }
    }
  }

  @override
  Future<Try<User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final supaUser = response.user;
      if (supaUser == null) {
        return Try.reject(KnownFailure('INVALID_CREDENTIALS', null));
      }
      _currentUser = _toUser(supaUser);
      _accessToken = _normalizeToken(response.session?.accessToken);
      _refreshToken = response.session?.refreshToken;
      await _warmUpProfileForAvatar();
      await _saveLocalSession();
      return Try.success(_currentUser!);
    } on supa.AuthException catch (e) {
      return Try.reject(
        KnownFailure(e.statusCode ?? 'AUTH_ERROR', e, message: e.message),
      );
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<Try<User>> signInWithSocial({
    required String provider,
    required String idToken,
    String? nonce,
  }) async {
    if (kDebugMode) {
      debugPrint('[GoogleBFF] signInWithSocial iniciado: provider=$provider');
    }
    try {
      final payload = <String, dynamic>{
        'provider': provider,
        'id_token': idToken,
        if (nonce != null && nonce.trim().isNotEmpty) 'nonce': nonce,
      };

      final response = await _authService.socialExchange(payload);

      if (!response.isSuccessful) {
        if (kDebugMode) {
          debugPrint(
              '[GoogleBFF] ERRO: status ${response.statusCode}  error=${response.error}');
        }
        return Try.reject(KnownFailure('AUTH_ERROR', response.error,
            message: 'BFF returned ${response.statusCode}'));
      }

      final responseBody = JsonUtils.asMap(response.body);
      final userMap = JsonUtils.asMap(responseBody?['user']);
      if (userMap == null) {
        if (kDebugMode) {
          debugPrint('[GoogleBFF] ERRO: campo "user" ausente na resposta');
        }
        return Try.reject(KnownFailure('AUTH_ERROR', null));
      }

      _accessToken = _normalizeToken(responseBody?['access_token'] as String?);
      _refreshToken = responseBody?['refresh_token'] as String?;

      final user = User(
        id: (userMap['id'] as String?) ?? '',
        email: (userMap['email'] as String?) ?? '',
        name: (userMap['name'] as String?) ??
            (userMap['full_name'] as String?) ??
            (userMap['email'] as String?),
        avatarUrl: _readString(userMap['avatar_url']),
        onboardingCompleted:
            _readBool(userMap['onboarding_completed']) ?? false,
      );
      _currentUser = user;
      await _warmUpProfileForAvatar();
      await _saveLocalSession();
      return Try.success(_currentUser!);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GoogleBFF] ERRO em signInWithSocial: $e');
      }
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<Try<SignUpResult>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      final supaUser = response.user;
      if (supaUser == null) {
        return Try.reject(KnownFailure('SIGN_UP_FAILED', null));
      }
      final user = _toUser(supaUser);
      final session = response.session;

      // Confirmação de e-mail ativa: o Supabase cria o usuário mas não
      // devolve sessão. Não guardamos nada localmente — senão o app
      // "entrava" sem token e as chamadas autenticadas falhavam com 401.
      if (session == null) {
        return Try.success(
          SignUpResult(user: user, requiresEmailConfirmation: true),
        );
      }

      _currentUser = user;
      _accessToken = _normalizeToken(session.accessToken);
      _refreshToken = session.refreshToken;
      unawaited(_warmUpProfileForAvatar());
      await _saveLocalSession();
      return Try.success(
        SignUpResult(user: user, requiresEmailConfirmation: false),
      );
    } on supa.AuthException catch (e) {
      return Try.reject(
        KnownFailure(e.statusCode ?? 'AUTH_ERROR', e, message: e.message),
      );
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<Try<void>> refreshSession() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return Try.reject(KnownFailure('MISSING_REFRESH_TOKEN', null));
    }

    try {
      final response = await _authService.refresh(
        <String, dynamic>{'refresh_token': refreshToken},
      );
      if (!response.isSuccessful) {
        return Try.reject(KnownFailure('AUTH_ERROR', response.error,
            message: 'BFF returned ${response.statusCode}'));
      }
      final responseBody = JsonUtils.asMap(response.body);
      _accessToken = _normalizeToken(responseBody?['access_token'] as String?);
      _refreshToken = responseBody?['refresh_token'] as String? ?? refreshToken;
      await _saveLocalSession();
      return Try.success(null);
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<void> refreshCurrentUserProfile() async {
    await _warmUpProfileForAvatar();
  }

  @override
  Future<Try<List<OnboardingQuestion>>> getOnboardingQuiz() async {
    try {
      final response = await _profileService.getOnboardingQuiz();
      if (!response.isSuccessful) {
        return Try.reject(_onboardingHttpFailure(response));
      }

      final questions = OnboardingQuestionModel.tryParseQuiz(response.body);
      if (questions == null) {
        return Try.reject(KnownFailure(
          OnboardingFailureCode.invalidResponse,
          response.bodyString,
          message: 'Resposta de /onboarding/quiz fora do contrato',
        ));
      }

      return Try.success(
        questions.map((q) => q.toEntity()).toList(growable: false),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthRepository] erro ao carregar quiz de onboarding: $e');
      }
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<Try<OnboardingResult>> submitOnboardingQuiz({
    required List<int> selectedOptionIds,
  }) async {
    try {
      // O token é injetado pelo AuthHeaderInterceptor.
      final response = await _profileService.submitOnboardingQuiz({
        'selected_option_ids': selectedOptionIds,
      });

      if (!response.isSuccessful) {
        return Try.reject(_onboardingHttpFailure(response));
      }

      return Try.success(
        OnboardingResultModel.fromJson(response.body).toEntity(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthRepository] erro ao enviar quiz de onboarding: $e');
      }
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  Future<User?> markOnboardingCompleted() async {
    final user = getCurrentUser();
    if (user == null) return null;
    _currentUser = user.copyWith(onboardingCompleted: true);
    await _saveLocalSession();
    return _currentUser;
  }

  /// Traduz o status HTTP de uma resposta de onboarding para um
  /// [KnownFailure] com código de [OnboardingFailureCode].
  KnownFailure _onboardingHttpFailure(Response<dynamic> response) {
    final statusCode = response.statusCode;
    final String code;
    if (statusCode == 400) {
      code = OnboardingFailureCode.invalidAnswers;
    } else if (statusCode == 401) {
      code = OnboardingFailureCode.unauthorized;
    } else if (statusCode >= 500) {
      code = OnboardingFailureCode.server;
    } else {
      code = OnboardingFailureCode.requestFailed;
    }

    final backendMessage =
        JsonUtils.readErrorMessage(response.error ?? response.bodyString);
    if (kDebugMode) {
      debugPrint(
          '[AuthRepository] onboarding HTTP $statusCode -> $code ($backendMessage)');
    }
    return KnownFailure(
      code,
      response.error,
      message: backendMessage ?? 'HTTP $statusCode',
    );
  }

  @override
  Future<Try<void>> logout() async {
    final accessToken = _normalizeToken(_accessToken);
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        await _authService.logout(
          const <String, dynamic>{},
          authorization: 'Bearer $accessToken',
        );
      }
      await _client.auth.signOut();
      return Try.success(null);
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    } finally {
      // Sempre limpa o estado em memória: sem isso, uma falha de rede no
      // logout mantinha o usuário "logado" e o LoginPage o redirecionava de
      // volta (ex.: loop sessão expirada -> login -> onboarding).
      _accessToken = null;
      _refreshToken = null;
      _currentUser = null;
      await _clearLocalSession();
    }
  }

  @override
  Future<User?> restoreSession() async {
    await _restoreFuture;

    final user = getCurrentUser();
    final token = getAccessToken();
    if (user == null || token == null || token.isEmpty) return null;

    // Access token do Supabase expira (~1h). Se o salvo venceu, renova com o
    // refresh token; sem conseguir renovar, pede login de novo em vez de
    // abrir o app e tomar 401 em todas as chamadas.
    if (_isExpired(token)) {
      final refreshed = await refreshSession();
      if (refreshed.isLeft()) {
        if (kDebugMode) {
          debugPrint('[AuthRepository] sessão expirada e refresh falhou');
        }
        return null;
      }
    }

    // Fonte da verdade do onboarding é a API (existe taste_profile?).
    // Falha/timeout: segue com o valor salvo localmente.
    try {
      await _warmUpProfileForAvatar().timeout(_profileRefreshTimeout);
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('[AuthRepository] /me/profile demorou; usando sessão local');
      }
    }
    return _currentUser;
  }

  /// `true` se o JWT vence em menos de 60s (ou não dá para ler o `exp`).
  bool _isExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = JsonUtils.asMap(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = JsonUtils.readInt(payload?['exp']);
      if (exp == null) return false;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now()
          .isAfter(expiresAt.subtract(const Duration(seconds: 60)));
    } catch (_) {
      return false;
    }
  }

  @override
  User? getCurrentUser() {
    if (_currentUser != null) {
      return _currentUser;
    }
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) return null;
    _currentUser = _toUser(supaUser);
    return _currentUser;
  }

  @override
  String? getAccessToken() {
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      return _normalizeToken(_accessToken);
    }
    return _normalizeToken(_client.auth.currentSession?.accessToken);
  }

  String? _normalizeToken(String? token) {
    if (token == null) return null;

    final normalized = token.trim();
    if (normalized.isEmpty) return null;

    if (normalized.toLowerCase().startsWith('bearer ')) {
      final stripped = normalized.substring(7).trim();
      return stripped.isEmpty ? null : stripped;
    }

    return normalized;
  }

  Future<void> _warmUpProfileForAvatar() async {
    final accessToken = getAccessToken();
    if (accessToken == null || accessToken.isEmpty || _currentUser == null) {
      return;
    }

    try {
      final response = await _profileService.getMyProfile(
        authorization: _toAuthorization(accessToken),
      );
      if (!response.isSuccessful) {
        return;
      }

      final body = JsonUtils.asMap(response.body);
      if (body == null) {
        return;
      }

      final current = _currentUser;
      if (current == null) return;
      _currentUser = User(
        // `/v1/me/profile` retorna "user_id"; "id" mantido por compatibilidade.
        id: _readString(body['user_id']) ??
            _readString(body['id']) ??
            current.id,
        email: _readString(body['email']) ?? current.email,
        name: _readString(body['full_name']) ?? current.name,
        avatarUrl: _readString(body['avatar_url']) ?? current.avatarUrl,
        onboardingCompleted: _readBool(body['onboarding_completed']) ??
            current.onboardingCompleted,
      );
      await _saveLocalSession();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AvatarProvision] erro no warm-up de perfil: $e');
      }
    }
  }

  String? _readString(dynamic value) => JsonUtils.readString(value);

  bool? _readBool(dynamic value) => JsonUtils.readBool(value);

  String _toAuthorization(String token) {
    final normalized = token.trim();
    if (normalized.toLowerCase().startsWith('bearer ')) {
      return normalized;
    }
    return 'Bearer $normalized';
  }

  User _toUser(supa.User supaUser) {
    return User(
      id: supaUser.id,
      email: supaUser.email ?? '',
      name: supaUser.userMetadata?['name'] as String?,
      avatarUrl: _readString(supaUser.userMetadata?['avatar_url']) ??
          _readString(supaUser.userMetadata?['picture']),
    );
  }
}
