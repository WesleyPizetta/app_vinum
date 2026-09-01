import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../../domain/entity/recommended_wine.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import 'recommended_wine_card.dart';

/// Lista com scroll horizontal contendo as sugestões de vinhos recomendados.
/// O espaçamento e largura dos cards garantem a sensação de continuidade (estilo Netflix carousel).
class RecommendedWinesHorizontalList extends StatelessWidget {
  final List<RecommendedWine> recommendations;

  const RecommendedWinesHorizontalList({
    super.key,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(right: Dimens.spacing24),
        itemCount: recommendations.length,
        separatorBuilder: (_, __) => const SizedBox(width: Dimens.spacing12),
        itemBuilder: (context, index) {
          final wine = recommendations[index];
          return RecommendedWineCard(
            wine: wine,
            onFavoriteToggle: () {
              context.read<HomeBloc>().add(
                    HomeRecommendationFavoriteToggled(wineId: wine.id),
                  );
            },
            onTap: () {
              Navigator.pushNamed(
                context,
                ApplicationRoute.wineDetail,
                arguments: wine.id,
              );
            },
          );
        },
      ),
    );
  }
}
