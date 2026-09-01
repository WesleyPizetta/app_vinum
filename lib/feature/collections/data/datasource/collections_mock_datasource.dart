import 'package:flutter/material.dart';

import '../model/collection_item_model.dart';
import 'collections_datasource.dart';

class CollectionsMockDatasource implements CollectionsDatasource {
  @override
  Future<List<CollectionItemModel>> getCollections() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const [
      CollectionItemModel(
        id: '1',
        title: 'Vinhos Tintos Encorpados',
        icon: Icons.wine_bar,
      ),
      CollectionItemModel(
        id: '2',
        title: 'Brancos Refrescantes',
        icon: Icons.local_drink,
      ),
      CollectionItemModel(
        id: '3',
        title: 'Espumantes & Festivos',
        icon: Icons.celebration,
      ),
      CollectionItemModel(
        id: '4',
        title: 'Premiados & Raros',
        icon: Icons.workspace_premium,
      ),
    ];
  }
}
