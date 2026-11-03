import '../../domain/entity/post_auth_destination.dart';
import '../../domain/entity/user.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final User user;
  LoginSuccess({required this.user});

  /// Próxima tela: apelido (sem @handle) → quiz → home.
  PostAuthDestination get destination => PostAuthDestination.forUser(user);
}

class LoginError extends LoginState {
  final String message;
  LoginError({required this.message});
}
