import 'package:flutter/services.dart';

import '../../core/constants/assets.dart';
import '../../domain/repositories/map_style_repository_contract.dart';

/// Capa de datos: carga estilos de mapa desde assets.
class MapStyleRepository implements MapStyleRepositoryContract {
  const MapStyleRepository();

  @override
  Future<String> loadDarkStyle() async {
    return rootBundle.loadString(Assets.darkMapStyle);
  }
}
