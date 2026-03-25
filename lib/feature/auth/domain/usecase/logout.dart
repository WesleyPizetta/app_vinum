import 'package:essentials/essentials.dart';

import '../repository/auth_repository.dart';

class Logout {
  final AuthRepository _repository;

  Logout(this._repository);

  Future<Try<void>> call() => _repository.logout();
}
