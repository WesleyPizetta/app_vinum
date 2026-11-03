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

  @GET(path: '/onboarding/quiz')
  Future<Response<dynamic>> getOnboardingQuiz();

  @POST(path: '/onboarding/quiz/submit')
  Future<Response<dynamic>> submitOnboardingQuiz(
    @Body() Map<String, dynamic> body,
  );

  /// Público. Com token (injetado pelo `AuthHeaderInterceptor`), o apelido
  /// atual do usuário conta como disponível.
  /// `{"nickname": "wes_pizetta", "available": true}` ou
  /// `{"nickname": "...", "available": false, "code": "NICKNAME_TAKEN"}`.
  @GET(path: '/nicknames/check')
  Future<Response<dynamic>> checkNickname(
    @Query('nickname') String nickname,
  );

  /// Autenticado. Body `{"nickname": "wes_pizetta"}` →
  /// 200 `{"nickname": "wes_pizetta"}`; 409 `NICKNAME_TAKEN`;
  /// 422 `NICKNAME_*`; 400 corpo inválido; 401.
  @PUT(path: '/me/nickname')
  Future<Response<dynamic>> setMyNickname(
    @Body() Map<String, dynamic> body,
  );
}
