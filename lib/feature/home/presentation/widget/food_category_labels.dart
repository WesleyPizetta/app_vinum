import '../../domain/entity/food_category.dart';

/// Chaves i18n ligadas a [FoodCategory] (camada de apresentação).
extension FoodCategoryLabels on FoodCategory {
  /// Título da lista de vinhos (ex.: "Vinhos para Carnes").
  String get winesTitleKey => 'food_wines_title_$apiValue';

  /// Nome curto da comida (ex.: "Carnes"), usado nos chips da busca.
  String get searchLabelKey => 'search_food_$apiValue';

  /// Motivo "Harmoniza com ..." (ex.: "Harmoniza com carnes").
  String get pairsWithReasonKey => 'reason_pairs_with_$apiValue';
}
