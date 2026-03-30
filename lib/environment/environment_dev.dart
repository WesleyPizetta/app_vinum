import 'package:essentials/essentials.dart';

//TODO: Esse é só um exemplo, precisamos pensar em onde hospedar um docker/api
class DevEnvironment extends Environment {
  DevEnvironment({String? apiUrl, String? googleWebClientId})
      : super(
          isProduction: false,
          apiUrl: apiUrl ?? 'https://api-vinum-bff.onrender.com',
          name: 'DEV',
          googleWebClientId: googleWebClientId ?? '',
        );
}
