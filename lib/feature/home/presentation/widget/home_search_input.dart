import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../page/search_page.dart';

/// Campo de busca da home. É só um atalho: o toque em qualquer ponto abre a
/// [SearchPage], onde a busca de fato acontece (com foco automático).
class HomeSearchInput extends StatelessWidget {
  const HomeSearchInput({super.key});

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(SearchPage.route());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dimens.radiusXLarge),
      borderSide: BorderSide.none,
    );

    // O campo não recebe toques (nem foco/teclado na home).
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openSearch(context),
      child: IgnorePointer(
        child: TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: getString(context, 'search_wine_food_placeholder'),
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Dimens.spacing16,
              vertical: Dimens.spacing12,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: border,
            suffixIcon: Padding(
              padding: const EdgeInsets.all(Dimens.spacing4),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search,
                  size: Dimens.iconMedium,
                  color: theme.scaffoldBackgroundColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
