/// Valores que llegan del `.env` al compilar:
/// `flutter run --dart-define-from-file=.env`.
///
/// La clave de Google Maps también la leen Android (build.gradle.kts) e iOS
/// (xcconfig) directamente del `.env`; aquí solo se usa para saber si hay mapa.
class Env {
  const Env._();

  static const String googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static bool get hasMapsKey => googleMapsApiKey.isNotEmpty;
}
