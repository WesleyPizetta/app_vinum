/// Categoria de comida aceita pelo parâmetro `food` de
/// `GET /v1/me/recommendations`.
///
/// [apiValue] é exatamente o valor esperado pela API.
enum FoodCategory {
  meat('meat'),
  poultry('poultry'),
  pork('pork'),
  seafood('seafood'),
  pasta('pasta'),
  cheese('cheese'),
  vegetarian('vegetarian'),
  appetizer('appetizer'),
  dessert('dessert');

  final String apiValue;

  const FoodCategory(this.apiValue);

  /// Converte o valor da API (case-insensitive) na categoria, ou `null`.
  static FoodCategory? fromApiValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    for (final category in FoodCategory.values) {
      if (category.apiValue == normalized) return category;
    }
    return null;
  }
}
