import 'package:flutter/material.dart';

import '../../domain/entity/collection_item.dart';

class CollectionItemModel {
  final String id;
  final String title;
  final IconData icon;

  const CollectionItemModel({
    required this.id,
    required this.title,
    required this.icon,
  });

  CollectionItem toEntity() => CollectionItem(id: id, title: title, icon: icon);
}
