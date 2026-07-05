import 'package:chopper/chopper.dart';

part 'profile_api_service.chopper.dart';

@ChopperApi(baseUrl: '/v1')
abstract class ProfileApiService extends ChopperService {
  static ProfileApiService create([ChopperClient? client]) =>
      _$ProfileApiService(client);

  @GET(path: '/me/profile')
  Future<Response<dynamic>> getMyProfile({
    @Header('Authorization') required String authorization,
  });
}
