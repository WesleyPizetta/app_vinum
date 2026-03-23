import 'package:essentials/essentials.dart';

class ProdEnvironment extends Environment {
  ProdEnvironment({String? apiUrl, String? googleWebClientId})
      : super(
          isProduction: true,
          apiUrl: apiUrl ?? 'https://api.vinum.com',
          name: 'PROD',
          googleWebClientId: googleWebClientId ?? '',
        );
}
