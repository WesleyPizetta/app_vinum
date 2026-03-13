import 'package:essentials/essentials.dart';

import '../../feature/home/presentation/bloc/home_bloc.dart';

class VinumContainer {
  static void setup() {
    // BLoCs
    ApplicationContainer.registerFactory<HomeBloc>(() => HomeBloc());
  }
}
