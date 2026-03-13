import '../../domain/entity/wine.dart';

sealed class WineListState {}

class WineListInitial extends WineListState {}

class WineListLoading extends WineListState {}

class WineListLoaded extends WineListState {
  final List<Wine> wines;
  WineListLoaded({required this.wines});
}

class WineListError extends WineListState {
  final String message;
  WineListError({required this.message});
}
