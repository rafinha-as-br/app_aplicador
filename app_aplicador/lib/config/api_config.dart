/// URL base da API, definida no build, sem valor fixo no código:
/// `flutter run --dart-define=API_BASE_URL=http://localhost:8080`.
const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
