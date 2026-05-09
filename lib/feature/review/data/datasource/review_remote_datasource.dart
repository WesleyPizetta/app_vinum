import '../api/review_api_service.dart';
import '../model/review_model.dart';
import '../model/review_tag_option_model.dart';
import '../../domain/entity/review_tag.dart';
import 'review_datasource.dart';

class ReviewRemoteDatasource implements ReviewDatasource {
  final ReviewApiService _apiService;

  const ReviewRemoteDatasource(this._apiService);

  String _toAuthorization(String token) {
    final normalized = token.trim();
    if (normalized.toLowerCase().startsWith('bearer ')) {
      return normalized;
    }
    return 'Bearer $normalized';
  }

  @override
  Future<List<ReviewTagOption>> getTags() async {
    final response = await _apiService.getTags();
    if (response.isSuccessful && response.body != null) {
      final list = response.body as List<dynamic>;
      return list
          .map((e) => ReviewTagOptionModel.fromJson(e as Map<String, dynamic>))
          .map((m) => m.toEntity())
          .whereType<ReviewTagOption>()
          .toList();
    }
    throw Exception('Falha ao buscar tags: ${response.statusCode}');
  }

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
    required double nota,
    String? comentario,
    required List<ReviewTag> tags,
    required String token,
  }) async {
    final body = <String, dynamic>{
      'nota': nota,
      if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
      'tags': tags.map((t) => t.code).toList(),
    };
    final response = await _apiService.createReview(
      wineId,
      body,
      authorization: _toAuthorization(token),
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
    required List<ReviewTag> tags,
    required String token,
  }) async {
    final body = <String, dynamic>{
      'nota': nota,
      if (comentario != null) 'comentario': comentario,
      'tags': tags.map((t) => t.code).toList(),
    };
    final response = await _apiService.updateReview(
      id,
      body,
      authorization: _toAuthorization(token),
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
      authorization: _toAuthorization(token),
    );
    if (!response.isSuccessful) {
      throw Exception('Falha ao excluir avaliação: ${response.statusCode}');
    }
  }
}
