/// Backend base URL (no trailing slash).
///
/// Override when running or building, for example:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000`
///
/// Default [http://10.0.2.2:8000] targets the host machine from the Android emulator.
class AppConfig {
  AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
