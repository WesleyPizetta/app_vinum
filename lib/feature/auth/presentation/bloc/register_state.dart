import '../../domain/entity/user.dart';

abstract class RegisterState {}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {
  final User user;

  /// `true` quando o usuário precisa confirmar o e-mail antes de entrar
  /// (não há sessão ativa).
  final bool requiresEmailConfirmation;

  RegisterSuccess({
    required this.user,
    this.requiresEmailConfirmation = false,
  });
}

class RegisterError extends RegisterState {
  final String message;
  RegisterError({required this.message});
}
