import '../api/wine_api_service.dart';
import '../model/wine_model.dart';
import 'wine_datasource.dart';

/// Datasource remoto que consome a API de vinhos via Chopper.
///
/// Para ativar, troque [WineMockDatasource] por [WineRemoteDatasource]
/// no [VinumContainer]:
/// ```dart
/// ApplicationContainer.registerLazySingleton<WineDatasource>(
///   () => WineRemoteDatasource(resolve<WineApiService>()),
/// );
/// ```
// TODO: Ativar quando a API real estiver disponível
class WineRemoteDatasource implements WineDatasource {
  final WineApiService _apiService;

  const WineRemoteDatasource(this._apiService);

  @override
  Future<List<WineModel>> getWines() async {
    final response = await _apiService.getWines();
    if (response.isSuccessful && response.body != null) {
      final list = response.body as List<dynamic>;
      return list
          .map((json) => WineModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Falha ao buscar vinhos: ${response.statusCode}');
  }

  @override
  Future<WineModel> getWineById(String id) async {
    final response = await _apiService.getWineById(id);
    if (response.isSuccessful && response.body != null) {
      return WineModel.fromJson(response.body as Map<String, dynamic>);
    }
    throw Exception('Falha ao buscar vinho: ${response.statusCode}');
  }
}
