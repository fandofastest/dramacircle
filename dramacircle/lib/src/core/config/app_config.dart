class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backend-liart-delta-31.vercel.app/api',
  );
}
