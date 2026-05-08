import '../api/review_api_service.dart';
import '../model/review_model.dart';
import 'review_datasource.dart';

class ReviewRemoteDatasource implements ReviewDatasource {
  final ReviewApiService _apiService;

  const ReviewRemoteDatasource(this._apiService);

  @override
  Future<List<ReviewModel>> getWineReviews(String wineId) async {
    final response = await _apiService.getWineReviews(wineId);
    if (response.isSuccessful && response.body != null) {
      final list = response.body as List<dynamic>;
      return list
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Falha ao buscar avaliações: ${response.statusCode}');
  }

  @override
  Future<ReviewModel> createReview({
    required String wineId,
    required String usuarioId,
    required double nota,
    String? comentario,
    String? token,
  }) async {
    final body = <String, dynamic>{
      'usuario_id': usuarioId,
      'nota': nota,
      if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
    };
    final response = await _apiService.createReview(
      wineId,
      body,
      authorization: token != null ? 'Bearer $token' : null,
    );
    if (response.isSuccessful && response.body != null) {
      return ReviewModel.fromJson(response.body as Map<String, dynamic>);
    }
    throw Exception('Falha ao criar avaliação: ${response.statusCode}');
  }

  @override
  Future<ReviewModel> updateReview({
    required String id,
    required double nota,
    String? comentario,
    required String token,
  }) async {
    final body = <String, dynamic>{
      'nota': nota,
      if (comentario != null) 'comentario': comentario,
    };
    final response = await _apiService.updateReview(
      id,
      body,
      authorization: 'Bearer $token',
    );
    if (response.isSuccessful && response.body != null) {
      return ReviewModel.fromJson(response.body as Map<String, dynamic>);
    }
    throw Exception('Falha ao atualizar avaliação: ${response.statusCode}');
  }

  @override
  Future<void> deleteReview({required String id, required String token}) async {
    final response = await _apiService.deleteReview(
      id,
      authorization: 'Bearer $token',
    );
    if (!response.isSuccessful) {
      throw Exception('Falha ao excluir avaliação: ${response.statusCode}');
    }
  }
}
