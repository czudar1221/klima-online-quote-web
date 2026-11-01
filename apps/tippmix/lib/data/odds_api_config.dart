abstract final class OddsApiConfig {
  static const apiKey = String.fromEnvironment('ODDS_API_KEY');
  static bool get isConfigured => apiKey.isNotEmpty;
}
