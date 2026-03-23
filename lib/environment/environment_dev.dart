import 'package:essentials/essentials.dart';

//TODO: Esse é só um exemplo, precisamos pensar em onde hospedar um docker/api
class DevEnvironment extends Environment {
  DevEnvironment({String? apiUrl, String? googleWebClientId})
      : super(
          isProduction: false,
          apiUrl: apiUrl ?? 'http://10.0.2.2:8080',
          name: 'DEV',
          googleWebClientId: googleWebClientId ?? '',
        );
}
