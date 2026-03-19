import 'package:essentials/essentials.dart';

import '../entity/user.dart';
import '../repository/auth_repository.dart';

class SignUpParams {
  final String email;
  final String password;
  final String name;

  const SignUpParams({
    required this.email,
    required this.password,
    required this.name,
  });
}

class SignUp implements UseCase<User, SignUpParams> {
  final AuthRepository _repository;

  SignUp(this._repository);

  @override
  Future<Try<User>> call(SignUpParams params) => _repository.signUp(
        email: params.email,
        password: params.password,
        name: params.name,
      );
}
