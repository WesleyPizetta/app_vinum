import 'package:chopper/chopper.dart';

part 'review_api_service.chopper.dart';

@ChopperApi(baseUrl: '/v1')
abstract class ReviewApiService extends ChopperService {
  static ReviewApiService create([ChopperClient? client]) =>
      _$ReviewApiService(client);

  @GET(path: '/wines/{wine_id}/reviews')
  Future<Response<dynamic>> getWineReviews(@Path('wine_id') String wineId);

  @POST(path: '/wines/{wine_id}/reviews')
  Future<Response<dynamic>> createReview(
    @Path('wine_id') String wineId,
    @Body() Map<String, dynamic> body, {
    @Header('Authorization') String? authorization,
  });

  @PATCH(path: '/reviews/{id}')
  Future<Response<dynamic>> updateReview(
    @Path('id') String id,
    @Body() Map<String, dynamic> body, {
    @Header('Authorization') String? authorization,
  });

  @DELETE(path: '/reviews/{id}')
  Future<Response<dynamic>> deleteReview(
    @Path('id') String id, {
    @Header('Authorization') String? authorization,
  });
}
