import 'package:essentials/essentials.dart';

import '../../../../core/session/session_cache.dart';
import '../repository/auth_repository.dart';

class Logout {
  final AuthRepository _repository;

  /// Caches em memória da sessão (ex.: favoritos) limpos a cada logout,
  /// inclusive quando o logout na API falha.
  final List<SessionCache> _sessionCaches;

  Logout(this._repository, [this._sessionCaches = const []]);

  Future<Try<void>> call() async {
    try {
      return await _repository.logout();
    } finally {
      for (final cache in _sessionCaches) {
        cache.clear();
      }
    }
  }
}
