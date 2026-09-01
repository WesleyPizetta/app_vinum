import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

class ThemeOptionItem {
  final ThemeMode mode;
  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final Color activeColor;

  const ThemeOptionItem({
    required this.mode,
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.activeColor,
  });
}

class ThemeSelectorCard extends StatelessWidget {
  final ThemeMode selectedMode;
  final ValueChanged<ThemeMode> onThemeSelected;

  const ThemeSelectorCard({
    super.key,
    required this.selectedMode,
    required this.onThemeSelected,
  });

  static const List<ThemeOptionItem> _options = [
    ThemeOptionItem(
      mode: ThemeMode.system,
      titleKey: 'theme_mode_system',
      subtitleKey: 'theme_mode_system_subtitle',
      icon: Icons.brightness_auto_rounded,
      activeColor: Color(0xFF4A90A4),
    ),
    ThemeOptionItem(
      mode: ThemeMode.light,
      titleKey: 'theme_mode_light',
      subtitleKey: 'theme_mode_light_subtitle',
      icon: Icons.wb_sunny_rounded,
      activeColor: Color(0xFFBD5A6A),
    ),
    ThemeOptionItem(
      mode: ThemeMode.dark,
      titleKey: 'theme_mode_dark',
      subtitleKey: 'theme_mode_dark_subtitle',
      icon: Icons.nights_stay_rounded,
      activeColor: Color(0xFFDDA84F),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimens.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimens.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: Dimens.iconMedium,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: Dimens.spacing12),
                Text(
                  getString(context, 'theme_section_title'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimens.spacing16),
            Column(
              children: _options.map((option) {
                final isSelected = selectedMode == option.mode;
                return Padding(
                  padding: const EdgeInsets.only(bottom: Dimens.spacing8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(Dimens.radiusMedium),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.dividerColor.withValues(alpha: 0.5),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(Dimens.radiusMedium),
                      onTap: () => onThemeSelected(option.mode),
                      child: Padding(
                        padding: const EdgeInsets.all(Dimens.spacing12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: option.activeColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                option.icon,
                                color: option.activeColor,
                                size: Dimens.iconMedium,
                              ),
                            ),
                            const SizedBox(width: Dimens.spacing16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getString(context, option.titleKey),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: Dimens.spacing2),
                                  Text(
                                    getString(context, option.subtitleKey),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3),
                              size: Dimens.iconMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
