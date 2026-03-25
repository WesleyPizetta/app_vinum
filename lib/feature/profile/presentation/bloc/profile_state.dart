import '../../../auth/domain/entity/user.dart';

sealed class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final User user;
  ProfileLoaded({required this.user});
}

class ProfileLoggingOut extends ProfileState {}

class ProfileLoggedOut extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;
  ProfileError({required this.message});
}
