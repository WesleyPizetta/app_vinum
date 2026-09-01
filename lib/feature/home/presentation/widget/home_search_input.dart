import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';

class HomeSearchInput extends StatelessWidget {
  const HomeSearchInput({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusXLarge),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusXLarge),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusXLarge),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
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
      onSubmitted: (query) {
        if (query.trim().isNotEmpty) {
          Navigator.pushNamed(
            context,
            ApplicationRoute.wineList,
          );
        }
      },
    );
  }
}
