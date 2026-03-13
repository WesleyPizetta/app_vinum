import 'package:essentials/essentials.dart';

class ProdEnvironment extends Environment {
  ProdEnvironment()
      : super(
          isProduction: true,
          apiUrl: 'https://api.vinum.com',
          name: 'PROD',
        );
}
