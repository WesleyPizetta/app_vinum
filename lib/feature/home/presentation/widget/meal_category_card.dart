import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../../../core/navigation/application_route.dart';

class MealCategoryItem {
  final String labelKey;
  final Color backgroundColor;
  final String? svgAsset;
  final IconData? fallbackIcon;

  const MealCategoryItem({
    required this.labelKey,
    required this.backgroundColor,
    this.svgAsset,
    this.fallbackIcon,
  });
}

class MealCategoryCard extends StatelessWidget {
  final MealCategoryItem item;

  const MealCategoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, ApplicationRoute.wineList);
      },
      borderRadius: BorderRadius.circular(Dimens.radiusLarge),
      child: Container(
        width: 80,
        height: 104,
        padding: const EdgeInsets.symmetric(
          horizontal: Dimens.spacing8,
          vertical: Dimens.spacing12,
        ),
        decoration: BoxDecoration(
          color: item.backgroundColor,
          borderRadius: BorderRadius.circular(Dimens.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: item.backgroundColor.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: item.svgAsset != null
                    ? SvgPicture.asset(
                        item.svgAsset!,
                        width: 38,
                        height: 38,
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        item.fallbackIcon,
                        size: 32,
                        color: Colors.white,
                      ),
              ),
            ),
            const SizedBox(height: Dimens.spacing4),
            Text(
              getString(context, item.labelKey),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
