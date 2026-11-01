import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class LocalStore {
  static const _userMatchesKey = 'user_matches_v1';
  static const _historyKey = 'history_v1';

  Future<List<SportsMatch>> loadUserMatches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userMatchesKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list)
        SportsMatch.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> saveUserMatches(List<SportsMatch> matches) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _userMatchesKey,
      jsonEncode([for (final m in matches) m.toJson()]),
    );
  }

  Future<List<HistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list)
        HistoryEntry.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> saveHistory(List<HistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode([for (final e in entries) e.toJson()]),
    );
  }
}
