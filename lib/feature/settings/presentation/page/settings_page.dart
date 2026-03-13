import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final environment = ApplicationContainer.resolve<Environment>();

    return Scaffold(
      appBar: VinumAppBar(
        title: getString(context, 'settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Dimens.spacing16),
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Ambiente'),
            subtitle: Text(environment.name),
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('API URL'),
            subtitle: Text(environment.apiUrl),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Tema'),
            subtitle: Text('Vinum palette'),
            trailing: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              radius: 12,
            ),
          ),
        ],
      ),
    );
  }
}
