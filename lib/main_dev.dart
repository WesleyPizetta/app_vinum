import 'package:essentials/essentials.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/di/vinum_container.dart';
import 'environment/environment_dev.dart';
import 'vinum_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  if (kIsWeb) {
    final apiKey = dotenv.env['FIREBASE_WEB_API_KEY'] ?? dotenv.env['FIREBASE_API_KEY'];
    final appId = dotenv.env['FIREBASE_WEB_APP_ID'] ?? dotenv.env['FIREBASE_APP_ID'];
    final messagingSenderId = dotenv.env['FIREBASE_WEB_MESSAGING_SENDER_ID'] ?? '1234567890';
    final projectId = dotenv.env['FIREBASE_WEB_PROJECT_ID'] ?? dotenv.env['FIREBASE_PROJECT_ID'] ?? 'vinum-dev';

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: apiKey ?? 'dev-api-key',
        appId: appId ?? '1:1234567890:web:1234567890',
        messagingSenderId: messagingSenderId,
        projectId: projectId,
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

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
