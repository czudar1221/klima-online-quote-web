/// Compile-time secrets from `--dart-define-from-file=.env`.
/// Never log [apiKey].
abstract final class OpenAiConfig {
  static const apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const model = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-4o',
  );

  static bool get isConfigured => apiKey.isNotEmpty;
}
