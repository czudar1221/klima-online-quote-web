import 'dart:convert';

import 'package:http/http.dart' as http;

import '../engine/rational.dart';
import '../l10n/copy.dart';
import 'openai_config.dart';

/// Optional Hungarian prose about *already computed* numbers.
/// Must never be used as the source of the displayed percent.
class OpenAiExplainer {
  OpenAiExplainer({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> explain({
    required Rational winChance,
    required String summary,
    required bool isAccumulator,
    required int requiredHits,
    required int legCount,
    String? blendNote,
  }) async {
    if (!OpenAiConfig.isConfigured) {
      return Copy.explainOffline;
    }

    final percent = winChance.toPercentString();
    final mode = isAccumulator ? 'szelvény (minden láb)' : 'kombináció';
    final user =
        'A matematikai motor már kiszámolta a nyerési esélyt: $percent.\n'
        'Összefoglaló: $summary\n'
        'Mód: $mode, lábak: $legCount, szükséges találatok: $requiredHits.\n'
        '${blendNote ?? ''}\n'
        'Írj 2–4 rövid magyar mondatot. Ismételd meg ezt a százalékot változtatás nélkül. '
        'Ne adj új számot, ne jósolj győztest, ne állítsd biztosnak a kimenetelt.';

    try {
      final response = await _client.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${OpenAiConfig.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': OpenAiConfig.model,
          'temperature': 0.2,
          'messages': [
            {
              'role': 'system',
              'content':
                  'Magyar nyelvű sportfogadási magyarázó vagy. '
                  'Kizárólag magyarul írsz. '
                  'A százalékot a felhasználó üzenetéből veszed, soha nem számítod újra és nem módosítod. '
                  'Rövid, prémium hangnem. Nem ijesztő. Nem garancia.',
            },
            {'role': 'user', 'content': user},
          ],
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Copy.explainUnavailable;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return Copy.explainUnavailable;
      }
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) {
        return Copy.explainUnavailable;
      }
      final message = choices.first['message'];
      final content = message is Map ? message['content'] : null;
      if (content is! String || content.trim().isEmpty) {
        return Copy.explainUnavailable;
      }
      return content.trim();
    } catch (_) {
      return Copy.explainUnavailable;
    }
  }
}
