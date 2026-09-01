import 'package:essentials/essentials.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/di/vinum_container.dart';
import 'environment/environment_prod.dart';
import 'vinum_app.dart';

String _requiredFirebaseWebValue(String key) {
  final value = dotenv.env[key]?.trim();
  if (value == null || value.isEmpty) {
    throw StateError('Missing required Firebase web configuration: $key');
  }
  return value;
}

// TODO: Em produção, considere injetar as chaves via --dart-define
// em vez de .env em assets, pois assets são visíveis no APK.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env.prod');

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: _requiredFirebaseWebValue('FIREBASE_WEB_API_KEY'),
        appId: _requiredFirebaseWebValue('FIREBASE_WEB_APP_ID'),
        messagingSenderId:
            _requiredFirebaseWebValue('FIREBASE_WEB_MESSAGING_SENDER_ID'),
        projectId: _requiredFirebaseWebValue('FIREBASE_WEB_PROJECT_ID'),
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
    ProdEnvironment(
      apiUrl: dotenv.env['BFF_API_URL'],
      googleWebClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    ),
  );
  VinumContainer.setup();

  runApp(const VinumApp());
}
