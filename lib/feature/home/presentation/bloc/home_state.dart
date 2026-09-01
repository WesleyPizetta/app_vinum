import '../../../auth/domain/entity/user.dart';
import '../../domain/entity/highlight_wine.dart';
import '../../domain/entity/recommended_wine.dart';

sealed class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final String welcomeMessage;
  final User? currentUser;
  final List<RecommendedWine> recommendations;
  final List<HighlightWine> highlights;

  HomeLoaded({
    required this.welcomeMessage,
    this.currentUser,
    this.recommendations = const [],
    this.highlights = const [],
  });
}

class HomeError extends HomeState {
  final String message;
  HomeError({required this.message});
}
