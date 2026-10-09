import '../../../wine/domain/entity/wine.dart';

/// Item de `GET /v1/me/favorites`: os dados do vinho (mesmo contrato de
/// `GET /v1/wines/{id}`) e quando ele foi favoritado.
class FavoriteWine {
  final Wine wine;
  final DateTime? favoritedAt;

  const FavoriteWine({required this.wine, this.favoritedAt});

  String get id => wine.id;
}
