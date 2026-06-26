/// App-wide configuration.
class AppConfig {
  /// Deployed Quicks backend. The API lives under /api/v1.
  static const String apiBaseUrl = 'https://quicks-backend-api.onrender.com';

  /// Render's free tier cold-starts (~30s) after idle, so use generous timeouts.
  static const Duration connectTimeout = Duration(seconds: 40);
  static const Duration receiveTimeout = Duration(seconds: 40);
}
