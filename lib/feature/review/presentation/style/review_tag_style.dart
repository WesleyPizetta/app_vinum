import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/review_tag.dart';

class ReviewTagBadgeStyle {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  const ReviewTagBadgeStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });
}

String localizedReviewTagLabel(BuildContext context, ReviewTag tag) {
  return switch (tag) {
    ReviewTag.amadeirado => getString(context, 'review_tag_amadeirado'),
    ReviewTag.suave => getString(context, 'review_tag_suave'),
    ReviewTag.encorpado => getString(context, 'review_tag_encorpado'),
    ReviewTag.frutado => getString(context, 'review_tag_frutado'),
    ReviewTag.seco => getString(context, 'review_tag_seco'),
    ReviewTag.citrico => getString(context, 'review_tag_citrico'),
  };
}

ReviewTagBadgeStyle resolveReviewTagBadgeStyle(
  BuildContext context, {
  required ReviewTag tag,
  required bool selected,
}) {
  final theme = Theme.of(context);
  final baseColor = _baseColor(tag);

  if (selected) {
    return ReviewTagBadgeStyle(
      backgroundColor: baseColor,
      foregroundColor: _onColor(theme.colorScheme, baseColor),
      borderColor: baseColor,
    );
  }

  return ReviewTagBadgeStyle(
    backgroundColor: Color.lerp(theme.colorScheme.surface, baseColor, 0.16)!,
    foregroundColor: Color.lerp(theme.colorScheme.onSurface, baseColor, 0.62)!,
    borderColor: Color.lerp(theme.dividerColor, baseColor, 0.45)!,
  );
}

Color _onColor(ColorScheme colorScheme, Color background) {
  final brightness = ThemeData.estimateBrightnessForColor(background);
  return brightness == Brightness.dark
      ? colorScheme.onPrimary
      : colorScheme.onSurface;
}

Color _baseColor(ReviewTag tag) {
  return switch (tag) {
    ReviewTag.amadeirado => const Color(0xFF8B5E3C),
    ReviewTag.suave => const Color(0xFFC77E96),
    ReviewTag.encorpado => const Color(0xFF7C283A),
    ReviewTag.frutado => const Color(0xFFCC6344),
    ReviewTag.seco => const Color(0xFF757257),
    ReviewTag.citrico => const Color(0xFFBA9A34),
  };
}
