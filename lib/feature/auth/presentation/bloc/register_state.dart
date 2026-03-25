import '../../domain/entity/user.dart';

abstract class RegisterState {}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {
  final User user;
  RegisterSuccess({required this.user});
}

class RegisterError extends RegisterState {
  final String message;
  RegisterError({required this.message});
}
