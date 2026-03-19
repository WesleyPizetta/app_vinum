import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/di/vinum_container.dart';
import 'environment/environment_dev.dart';
import 'vinum_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  ApplicationContainer.registerSingleton<Environment>(DevEnvironment());
  VinumContainer.setup();

  runApp(const VinumApp());
}
