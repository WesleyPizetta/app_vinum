import 'package:essentials/essentials.dart';

//TODO: Esse é só um exemplo, precisamos pensar em onde hospedar um docker/api
class DevEnvironment extends Environment {
  DevEnvironment()
      : super(
          isProduction: false,
          apiUrl: 'https://dev-api.vinum.com',
          name: 'DEV',
        );
}
