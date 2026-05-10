import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../../domain/entity/review_tag.dart';
import '../style/review_tag_style.dart';

class ReviewTagBadge extends StatelessWidget {
  final ReviewTag tag;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  const ReviewTagBadge({
    super.key,
    required this.tag,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = resolveReviewTagBadgeStyle(
      context,
      tag: tag,
      selected: selected,
    );

    return Material(
      color: style.backgroundColor,
      shape: StadiumBorder(
        side: BorderSide(color: style.borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? Dimens.spacing8 : Dimens.spacing12,
            vertical: compact ? Dimens.spacing4 : Dimens.spacing8,
          ),
          child: Text(
            localizedReviewTagLabel(context, tag),
            style: theme.textTheme.labelMedium?.copyWith(
              color: style.foregroundColor,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
