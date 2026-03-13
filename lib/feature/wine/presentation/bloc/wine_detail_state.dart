import '../../domain/entity/wine.dart';

sealed class WineDetailState {}

class WineDetailInitial extends WineDetailState {}

class WineDetailLoading extends WineDetailState {}

class WineDetailLoaded extends WineDetailState {
  final Wine wine;
  WineDetailLoaded({required this.wine});
}

class WineDetailError extends WineDetailState {
  final String message;
  WineDetailError({required this.message});
}
