import '../../domain/entity/collection_item.dart';

sealed class CollectionsState {}

class CollectionsInitial extends CollectionsState {}

class CollectionsLoading extends CollectionsState {}

class CollectionsLoaded extends CollectionsState {
  final List<CollectionItem> collections;

  CollectionsLoaded({required this.collections});
}

class CollectionsError extends CollectionsState {
  final String message;

  CollectionsError({required this.message});
}
