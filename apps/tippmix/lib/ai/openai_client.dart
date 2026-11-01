import 'dart:convert';

import 'package:http/http.dart' as http;

import 'openai_config.dart';

class OpenAiException implements Exception {}

/// Chat Completions client. Never log [OpenAiConfig.apiKey].
class OpenAiClient {
  OpenAiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  bool get isConfigured => OpenAiConfig.isConfigured;

  Future<String> complete({
    required String system,
    required List<({String role, String content})> messages,
    int maxTokens = 500,
  }) async {
    if (!isConfigured) throw OpenAiException();
    final body = <String, Object?>{
      'model': OpenAiConfig.model,
      'temperature': 0.3,
      'max_tokens': maxTokens,
      'messages': [
        {'role': 'system', 'content': system},
        for (final m in messages) {'role': m.role, 'content': m.content},
      ],
    };
    final res = await _http.post(
      Uri.https('api.openai.com', '/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${OpenAiConfig.apiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw OpenAiException();
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) throw OpenAiException();
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) throw OpenAiException();
    final msg = (choices.first as Map)['message'];
    if (msg is! Map) throw OpenAiException();
    final content = msg['content'];
    if (content is! String || content.trim().isEmpty) throw OpenAiException();
    return content.trim();
  }
}
