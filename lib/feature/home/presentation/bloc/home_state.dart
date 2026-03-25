import '../../../auth/domain/entity/user.dart';

sealed class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final String welcomeMessage;
  final User? currentUser;
  HomeLoaded({required this.welcomeMessage, this.currentUser});
}

class HomeError extends HomeState {
  final String message;
  HomeError({required this.message});
}
