import '../../domain/entity/cellar_item.dart';

class CellarItemModel {
  final String id;
  final String name;
  final int count;

  const CellarItemModel({
    required this.id,
    required this.name,
    required this.count,
  });

  CellarItem toEntity() => CellarItem(id: id, name: name, count: count);
}
