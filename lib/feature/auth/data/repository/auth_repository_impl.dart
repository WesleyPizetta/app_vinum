import 'package:essentials/essentials.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../domain/entity/user.dart';
import '../../domain/repository/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final supa.SupabaseClient _client = supa.Supabase.instance.client;

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
      return Try.success(_toUser(supaUser));
    } on supa.AuthException catch (e) {
      return Try.reject(
        KnownFailure(e.statusCode ?? 'AUTH_ERROR', e, message: e.message),
      );
    } catch (e) {
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
      return Try.success(_toUser(supaUser));
    } on supa.AuthException catch (e) {
      return Try.reject(
        KnownFailure(e.statusCode ?? 'AUTH_ERROR', e, message: e.message),
      );
    } catch (e) {
      return Try.reject(UnknownFailure(e));
    }
  }

  @override
  User? getCurrentUser() {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) return null;
    return _toUser(supaUser);
  }

  User _toUser(supa.User supaUser) {
    return User(
      id: supaUser.id,
      email: supaUser.email ?? '',
      name: supaUser.userMetadata?['name'] as String?,
    );
  }
}
