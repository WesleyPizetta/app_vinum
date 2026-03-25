import 'package:essentials/essentials.dart';

import '../entity/user.dart';

abstract class AuthRepository {
  Future<Try<User>> signIn({
    required String email,
    required String password,
  });

  Future<Try<User>> signInWithSocial({
    required String provider,
    required String idToken,
    String? nonce,
  });

  Future<Try<User>> signUp({
    required String email,
    required String password,
    required String name,
  });

  Future<Try<void>> refreshSession();

  Future<Try<void>> logout();

  User? getCurrentUser();
}
