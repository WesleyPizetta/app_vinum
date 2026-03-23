import 'package:essentials/essentials.dart';

import '../entity/user.dart';

abstract class AuthRepository {
  Future<Try<User>> signIn({
    required String email,
    required String password,
  });

  Future<Try<User>> signUp({
    required String email,
    required String password,
    required String name,
  });

  User? getCurrentUser();
}
