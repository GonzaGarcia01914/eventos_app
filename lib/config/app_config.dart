/// Configuración global de la app.
///
/// Pasar al ejecutar:
/// `flutter run --dart-define=GOOGLE_MAPS_API_KEY=tu_clave`
class AppConfig {
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  static bool get hasGoogleMapsApiKey => googleMapsApiKey.isNotEmpty;
}
