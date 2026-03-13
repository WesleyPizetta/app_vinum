import '../model/wine_model.dart';
import 'wine_datasource.dart';

// TODO: Substituir por WineRemoteDatasource com Chopper apontando para API real
// TODO: Criar WineLocalDatasource com SQLite/Hive para cache offline
class WineMockDatasource implements WineDatasource {
  static const _mockWines = [
    WineModel(
      id: '1',
      name: 'Château Margaux 2015',
      winery: 'Château Margaux',
      region: 'Margaux, Bordeaux',
      country: 'França',
      grape: 'Cabernet Sauvignon',
      vintage: 2015,
      rating: 4.8,
      imageUrl: '',
      description:
          'Um Bordeaux clássico com notas de cassis, violeta e cedro. '
          'Taninos elegantes e final longo e persistente.',
    ),
    WineModel(
      id: '2',
      name: 'Tignanello 2018',
      winery: 'Antinori',
      region: 'Toscana',
      country: 'Itália',
      grape: 'Sangiovese',
      vintage: 2018,
      rating: 4.6,
      imageUrl: '',
      description:
          'Super toscano com blend de Sangiovese, Cabernet Sauvignon e '
          'Cabernet Franc. Notas de cereja madura, especiarias e baunilha.',
    ),
    WineModel(
      id: '3',
      name: 'Catena Zapata Malbec 2019',
      winery: 'Bodega Catena Zapata',
      region: 'Mendoza',
      country: 'Argentina',
      grape: 'Malbec',
      vintage: 2019,
      rating: 4.5,
      imageUrl: '',
      description:
          'Malbec de altitude com aromas de ameixa negra, chocolate amargo '
          'e notas florais. Corpo cheio e taninos aveludados.',
    ),
    WineModel(
      id: '4',
      name: 'Penfolds Grange 2017',
      winery: 'Penfolds',
      region: 'South Australia',
      country: 'Austrália',
      grape: 'Shiraz',
      vintage: 2017,
      rating: 4.9,
      imageUrl: '',
      description:
          'Ícone australiano. Shiraz potente com notas de amora, alcaçuz, '
          'cravinho e carvalho tostado. Estrutura monumental.',
    ),
    WineModel(
      id: '5',
      name: 'Casillero del Diablo Reserva 2021',
      winery: 'Concha y Toro',
      region: 'Valle Central',
      country: 'Chile',
      grape: 'Carménère',
      vintage: 2021,
      rating: 3.8,
      imageUrl: '',
      description:
          'Carménère encorpado com notas de pimentão, frutas vermelhas '
          'e um toque de especiarias. Excelente custo-benefício.',
    ),
  ];

  @override
  Future<List<WineModel>> getWines() async {
    // TODO: Substituir por chamada HTTP real (Dio, Retrofit, etc.)
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockWines;
  }

  @override
  Future<WineModel> getWineById(String id) async {
    // TODO: Substituir por chamada HTTP real
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockWines.firstWhere(
      (w) => w.id == id,
      orElse: () => throw Exception('Vinho não encontrado'),
    );
  }
}
