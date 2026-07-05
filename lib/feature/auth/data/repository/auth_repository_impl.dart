import 'dart:async';

import 'package:essentials/essentials.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../api/auth_api_service.dart';
import '../../../profile/data/api/profile_api_service.dart';
import '../../domain/entity/user.dart';
import '../../domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthApiService authService,
    required ProfileApiService profileService,
  })  : _authService = authService,
        _profileService = profileService;

  final supa.SupabaseClient _client = supa.Supabase.instance.client;
  final AuthApiService _authService;
  final ProfileApiService _profileService;

  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;

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
      await _warmUpProfileForAvatar();
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
    debugPrint('[GoogleBFF] signInWithSocial: provider=$provider');
    try {
      final payload = <String, dynamic>{
        'provider': provider,
        'id_token': idToken,
        if (nonce != null && nonce.trim().isNotEmpty) 'nonce': nonce,
      };
      debugPrint('[GoogleBFF] payload keys: ${payload.keys.join(', ')}');

      final response = await _authService.socialExchange(payload);
      debugPrint(
          '[GoogleBFF] resposta: status=${response.statusCode}  body=${response.body}');

      if (!response.isSuccessful) {
        debugPrint(
            '[GoogleBFF] ERRO: status ${response.statusCode}  error=${response.error}');
        return Try.reject(KnownFailure('AUTH_ERROR', response.error,
            message: 'BFF returned ${response.statusCode}'));
      }

      final responseBody = response.body as Map<String, dynamic>?;
      final userMap = responseBody?['user'] as Map<String, dynamic>?;
      if (userMap == null) {
        debugPrint('[GoogleBFF] ERRO: campo "user" ausente na resposta');
        return Try.reject(KnownFailure('AUTH_ERROR', null));
      }

      _accessToken = _normalizeToken(responseBody?['access_token'] as String?);
      _refreshToken = responseBody?['refresh_token'] as String?;
      debugPrint(
          '[GoogleBFF] access_token ${_accessToken == null ? 'NULL' : 'recebido'}  refresh_token ${_refreshToken == null ? 'NULL' : 'recebido'}');

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
      debugPrint(
          '[GoogleBFF] usuário criado: id=${user.id}  email=${user.email}');
      return Try.success(_currentUser!);
    } catch (e, st) {
      debugPrint('[GoogleBFF] ERRO inesperado em signInWithSocial: $e\n$st');
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
      // Best-effort para acionar geração de avatar no BFF.
      unawaited(_warmUpProfileForAvatar());
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
      return Try.success(null);
    } catch (e) {
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
        debugPrint(
          '[AvatarProvision] warm-up profile falhou: status=${response.statusCode}',
        );
        return;
      }

      final body = response.body;
      if (body is! Map<String, dynamic>) {
        debugPrint(
            '[AvatarProvision] resposta de perfil em formato inesperado');
        return;
      }

      final current = _currentUser!;
      _currentUser = User(
        id: _readString(body['id']) ?? current.id,
        email: _readString(body['email']) ?? current.email,
        name: _readString(body['full_name']) ?? current.name,
        avatarUrl: _readString(body['avatar_url']) ?? current.avatarUrl,
      );
    } catch (e, st) {
      debugPrint('[AvatarProvision] erro no warm-up de perfil: $e\n$st');
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
