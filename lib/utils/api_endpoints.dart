class ApiConfig {
  // Prioritas: --dart-define=API_BASE_URL | fallback emulator Android (10.0.2.2) | iOS simulator (localhost)
  static const String _envBase = String.fromEnvironment('API_BASE_URL');
  static const String baseUrl = _envBase != '' ? _envBase : 'http://localhost:3000/api';

  static const String authLogin = '$baseUrl/auth/login';
  static const String authRegister = '$baseUrl/auth/register';
  static const String authForgot = '$baseUrl/auth/forgot';
  static const String motorcycles = '$baseUrl/motorcycles';
  static const String rentals = '$baseUrl/rentals';
  static const String users = '$baseUrl/users';
  static const String usersMe = '$users/me';
  static const String usersPassword = '$users/me/password';
  static const String usersAvatar = '$users/me/avatar';

  static String motorcycleImage(int id) => '$motorcycles/$id/image';
  static String motorcycleImages(int id) => '$motorcycles/$id/images';
  static String motorcycleDeleteImage(int id, int imageId) => '$motorcycles/$id/images/$imageId';

  // Build absolute URL for relative file path (e.g. /uploads/...) based on API base host.
  static String absolute(String maybeRelative) {
    if (maybeRelative.startsWith('http://') || maybeRelative.startsWith('https://')) return maybeRelative;
    // Derive origin by removing trailing /api from baseUrl if present
    final apiIndex = baseUrl.indexOf('/api');
    final origin = apiIndex > 0 ? baseUrl.substring(0, apiIndex) : baseUrl;
    if (!maybeRelative.startsWith('/')) return '$origin/$maybeRelative';
    return '$origin$maybeRelative';
  }
}
