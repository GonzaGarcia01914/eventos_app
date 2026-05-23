/// Contrato de dominio para estilos de mapa.
abstract interface class MapStyleRepositoryContract {
  Future<String> loadDarkStyle();
}
