import '../api/wine_api_service.dart';
import '../model/wine_highlights_model.dart';
import '../model/wine_model.dart';
import 'wine_datasource.dart';

/// Erro HTTP da API de vinhos, com o status para o repositório mapear.
/// `statusCode = 0` indica resposta 2xx fora do contrato.
class WineApiException implements Exception {
  final int statusCode;
  final String message;

  const WineApiException(this.statusCode, this.message);

  @override
  String toString() => 'WineApiException($statusCode): $message';
}

/// Datasource remoto: `GET /v1/wines`, `GET /v1/wines/{id}` e
/// `GET /v1/wines/highlights` do BFF.
class WineRemoteDatasource implements WineDatasource {
  final WineApiService _apiService;

  const WineRemoteDatasource(this._apiService);

  @override
  Future<List<WineModel>> getWines() async {
    final response = await _apiService.getWines();
    if (!response.isSuccessful) {
      throw WineApiException(response.statusCode, 'list wines');
    }
    final wines = WineModel.tryParseList(response.body ?? response.bodyString);
    if (wines == null) {
      throw const WineApiException(0, 'invalid wines response');
    }
    return wines;
  }

  @override
  Future<WineModel> getWineById(String id) async {
    final response = await _apiService.getWineById(id);
    if (!response.isSuccessful) {
      throw WineApiException(response.statusCode, 'get wine $id');
    }
    final wine = WineModel.tryParse(response.body ?? response.bodyString);
    if (wine == null) {
      throw const WineApiException(0, 'invalid wine response');
    }
    return wine;
  }

  @override
  Future<WineHighlightsModel> getHighlights({int limit = 10}) async {
    final response = await _apiService.getHighlights(limit: limit);
    if (!response.isSuccessful) {
      throw WineApiException(response.statusCode, 'wine highlights');
    }
    final highlights =
        WineHighlightsModel.tryParse(response.body ?? response.bodyString);
    if (highlights == null) {
      throw const WineApiException(0, 'invalid highlights response');
    }
    return highlights;
  }
}
