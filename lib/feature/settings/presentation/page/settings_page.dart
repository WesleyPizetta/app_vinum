import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widget/theme_selector_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final environment = ApplicationContainer.resolve<Environment>();

    return Scaffold(
      appBar: VinumAppBar(
        title: getString(context, 'settings'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(Dimens.spacing16),
            children: [
              ThemeSelectorCard(
                selectedMode: state.themeMode,
                onThemeSelected: (mode) {
                  context.read<SettingsBloc>().add(SettingsThemeChanged(mode));
                },
              ),
              const SizedBox(height: Dimens.spacing16),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimens.radiusLarge),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(Dimens.spacing8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                          child: Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: const Text('Ambiente'),
                        subtitle: Text(environment.name),
                      ),
                      const Divider(indent: 16, endIndent: 16),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.15),
                          child: Icon(
                            Icons.link,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        title: const Text('API URL'),
                        subtitle: Text(environment.apiUrl),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
