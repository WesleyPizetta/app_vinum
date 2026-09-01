import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';
import '../../domain/entity/highlight_wine.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import 'highlight_wine_card.dart';

/// Lista horizontal contendo os "Destaques da Semana".
/// A largura dos cards (140px) e os espaçamentos garantem que o último card visível
/// fique parcialmente cortado na borda da tela (efeito carrossel Netflix).
class HighlightWinesHorizontalList extends StatelessWidget {
  final List<HighlightWine> highlights;

  const HighlightWinesHorizontalList({
    super.key,
    required this.highlights,
  });

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 195,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.only(right: Dimens.spacing24),
        itemCount: highlights.length,
        separatorBuilder: (_, __) => const SizedBox(width: Dimens.spacing12),
        itemBuilder: (context, index) {
          final wine = highlights[index];
          return HighlightWineCard(
            wine: wine,
            onFavoriteToggle: () {
              context.read<HomeBloc>().add(
                    HomeHighlightFavoriteToggled(wineId: wine.id),
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
