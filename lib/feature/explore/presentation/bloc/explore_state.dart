import '../../domain/entity/explore_item.dart';

sealed class ExploreState {}

class ExploreInitial extends ExploreState {}

class ExploreLoading extends ExploreState {}

class ExploreLoaded extends ExploreState {
  final List<ExploreItem> items;

  ExploreLoaded({required this.items});
}

class ExploreError extends ExploreState {
  final String message;

  ExploreError({required this.message});
}
