import 'package:essentials/essentials.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/di/vinum_container.dart';
import 'environment/environment_dev.dart';
import 'vinum_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  ApplicationContainer.registerSingleton<Environment>(
    DevEnvironment(
      apiUrl: dotenv.env['BFF_API_URL'],
      googleWebClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    ),
  );
  VinumContainer.setup();

  runApp(const VinumApp());
}
