import '../../domain/entity/cellar_item.dart';

sealed class CellarState {}

class CellarInitial extends CellarState {}

class CellarLoading extends CellarState {}

class CellarLoaded extends CellarState {
  final List<CellarItem> items;

  CellarLoaded({required this.items});
}

class CellarError extends CellarState {
  final String message;

  CellarError({required this.message});
}
