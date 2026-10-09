import 'package:flutter/material.dart';

import '../../../favorites/presentation/page/my_favorites_page.dart';

/// Aba "Coleções" da home. Por enquanto a única coleção é
/// "Meus favoritos" (lista real de `GET /v1/me/favorites`); o datasource
/// mock de coleções (`CollectionsBloc`) não é mais usado por esta tela.
class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context) => const MyFavoritesPage();
}
