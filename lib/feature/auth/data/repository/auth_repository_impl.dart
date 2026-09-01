import 'dart:async';

import 'package:essentials/essentials.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../api/auth_api_service.dart';
import '../../../profile/data/api/profile_api_service.dart';
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
    _initPersistence();
  }

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

      if (_currentUser == null) {
        final id = await _secureStorage.read(key: 'auth_user_id');
        final email = await _secureStorage.read(key: 'auth_user_email');
        if (id != null && id.isNotEmpty && email != null) {
          final name = await _secureStorage.read(key: 'auth_user_name');
          final avatar =
              await _secureStorage.read(key: 'auth_user_avatar_url');
          _currentUser = User(
            id: id,
            email: email,
            name: name,
            avatarUrl: avatar,
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
        await _secureStorage.write(key: 'auth_user_id', value: _currentUser!.id);
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
      } else {
        await _secureStorage.delete(key: 'auth_user_id');
        await _secureStorage.delete(key: 'auth_user_email');
        await _secureStorage.delete(key: 'auth_user_name');
        await _secureStorage.delete(key: 'auth_user_avatar_url');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthRepository] Erro ao salvar sessão segura: $e');
      }
    }
  }

  Future<void> _clearLocalSession() async {
    try {
      await _secureStorage.deleteAll();
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

      final responseBody = response.body as Map<String, dynamic>?;
      final userMap = responseBody?['user'] as Map<String, dynamic>?;
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
  Future<Try<User>> signUp({
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
      _currentUser = user;
      _accessToken = _normalizeToken(response.session?.accessToken);
      _refreshToken = response.session?.refreshToken;
      unawaited(_warmUpProfileForAvatar());
      await _saveLocalSession();
      return Try.success(user);
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
      final responseBody = response.body as Map<String, dynamic>?;
      _accessToken = _normalizeToken(responseBody?['access_token'] as String?);
      _refreshToken = responseBody?['refresh_token'] as String? ?? refreshToken;
      await _saveLocalSession();
      return Try.success(null);
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
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
      _accessToken = null;
      _refreshToken = null;
      _currentUser = null;
      await _clearLocalSession();
      return Try.success(null);
    } catch (e) {
      await _clearLocalSession();
      return Try.reject(UnknownFailure(e));
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

      final body = response.body;
      if (body is! Map<String, dynamic>) {
        return;
      }

      final current = _currentUser!;
      _currentUser = User(
        id: _readString(body['id']) ?? current.id,
        email: _readString(body['email']) ?? current.email,
        name: _readString(body['full_name']) ?? current.name,
        avatarUrl: _readString(body['avatar_url']) ?? current.avatarUrl,
      );
      await _saveLocalSession();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AvatarProvision] erro no warm-up de perfil: $e');
      }
    }
  }

  String? _readString(dynamic value) {
    if (value is! String) {
      return null;
    }
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

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
