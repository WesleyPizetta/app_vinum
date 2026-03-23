import 'package:essentials/essentials.dart';

import '../entity/user.dart';
import '../repository/auth_repository.dart';

class SignInParams {
  final String email;
  final String password;

  const SignInParams({required this.email, required this.password});
}

class SignIn implements UseCase<User, SignInParams> {
  final AuthRepository _repository;

  SignIn(this._repository);

  @override
  Future<Try<User>> call(SignInParams params) =>
      _repository.signIn(email: params.email, password: params.password);
}
