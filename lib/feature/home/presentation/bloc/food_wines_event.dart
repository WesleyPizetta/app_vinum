import '../../../favorites/domain/entity/favorite_ids.dart';
import '../../domain/entity/food_category.dart';

sealed class FoodWinesEvent {}

/// Carrega a primeira página da [food]. Também serve de "tentar novamente"
/// nos estados de erro/vazio.
class FoodWinesStarted extends FoodWinesEvent {
  final FoodCategory food;

  FoodWinesStarted(this.food);
}

/// Pede a próxima página (scroll perto do fim ou "tentar novamente" no
/// rodapé). Ignorado se já estiver carregando ou se não houver mais itens.
class FoodWinesLoadMoreRequested extends FoodWinesEvent {}

/// Pull-to-refresh: recarrega do offset 0 mantendo a lista atual na tela
/// até a resposta chegar.
class FoodWinesRefreshed extends FoodWinesEvent {}

/// Favoritar/desfavoritar um vinho da lista (otimista, com rollback).
class FoodWinesFavoriteToggled extends FoodWinesEvent {
  final String wineId;

  FoodWinesFavoriteToggled(this.wineId);
}

/// Interno: o cache de favoritos mudou (ex.: alterado em outra tela).
class FoodWinesFavoriteIdsChanged extends FoodWinesEvent {
  final FavoriteIds ids;

  FoodWinesFavoriteIdsChanged(this.ids);
}
