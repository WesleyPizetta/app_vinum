import 'package:flutter/material.dart';

import '../../dimens.dart';

/// Botão de ícone de notificações reutilizável com indicador (badge) de contagem.
class VinumNotificationButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? badgeColor;

  const VinumNotificationButton({
    super.key,
    this.unreadCount = 0,
    this.onPressed,
    this.color,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor =
        color ?? IconTheme.of(context).color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(right: Dimens.spacing8),
      child: IconButton(
        onPressed: onPressed,
        tooltip: 'Notificações',
        icon: Badge.count(
          count: unreadCount,
          isLabelVisible: unreadCount > 0,
          offset: const Offset(4, -4),
          backgroundColor: badgeColor ?? theme.colorScheme.secondary,
          textColor: theme.colorScheme.onSecondary,
          textStyle: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
          child: Icon(
            Icons.notifications_outlined,
            size: Dimens.iconMedium,
            color: effectiveIconColor,
          ),
        ),
      ),
    );
  }
}
