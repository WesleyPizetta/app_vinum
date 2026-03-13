import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import 'core/di/vinum_container.dart';
import 'environment/environment_dev.dart';
import 'vinum_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  ApplicationContainer.registerSingleton<Environment>(DevEnvironment());
  VinumContainer.setup();

  runApp(const VinumApp());
}
