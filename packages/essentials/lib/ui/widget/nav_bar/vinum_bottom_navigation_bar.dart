import 'package:flutter/material.dart';
import '../../colors/vinum_palette.dart';
import '../../dimens.dart';

/// Item de navegação para a [VinumBottomNavigationBar].
class VinumNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const VinumNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

/// Componente reutilizável de barra de navegação inferior com animação e botão central flutuante.
class VinumBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<VinumNavItem> leftItems;
  final List<VinumNavItem> rightItems;

  const VinumBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.leftItems,
    required this.rightItems,
  });

  @override
  Widget build(BuildContext context) {
    final palette = VinumPalette();

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: Dimens.spacing8,
      clipBehavior: Clip.antiAlias,
      elevation: Dimens.elevationMedium,
      color: palette.surface,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Oeste (Oeste 1 e Oeste 2)
            ...List.generate(leftItems.length, (index) {
              final item = leftItems[index];
              final isSelected = currentIndex == index;
              return Expanded(
                child: _NavBarItemWidget(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onTap(index),
                ),
              );
            }),

            // Espaço reservado para o FAB central (Escanear)
            const SizedBox(width: Dimens.spacing56),

            // Leste (Leste 1 e Leste 2)
            ...List.generate(rightItems.length, (index) {
              final item = rightItems[index];
              final actualIndex = leftItems.length + index;
              final isSelected = currentIndex == actualIndex;
              return Expanded(
                child: _NavBarItemWidget(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onTap(actualIndex),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _NavBarItemWidget extends StatelessWidget {
  final VinumNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return InkWell(
      onTap: onTap,
      splashColor: activeColor.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(Dimens.radiusMedium),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: isSelected ? 1.18 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.spacing12,
                vertical: Dimens.spacing4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(Dimens.radiusLarge),
              ),
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: Dimens.iconMedium,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ),
          const SizedBox(height: Dimens.spacing2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: theme.textTheme.labelSmall!.copyWith(
              color: isSelected ? activeColor : inactiveColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
