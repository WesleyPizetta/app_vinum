import 'package:essentials/essentials.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vinum/core/di/vinum_container.dart';
import 'package:vinum/environment/environment_dev.dart';
import 'package:vinum/feature/auth/presentation/page/login_page.dart';
import 'package:vinum/vinum_app.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test_anon_key',
    );
    if (!ApplicationContainer.isRegistered<Environment>()) {
      ApplicationContainer.registerSingleton<Environment>(
        DevEnvironment(
          apiUrl: 'http://localhost:8080',
          googleWebClientId: 'test_client_id',
        ),
      );
      VinumContainer.setup();
    }
  });

  testWidgets('VinumApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const VinumApp());
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
  });
}

