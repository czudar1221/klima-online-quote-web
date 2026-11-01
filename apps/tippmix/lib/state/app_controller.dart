import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../ai/openai_client.dart';
import '../data/feed_error.dart';
import '../data/live_feed.dart';
import '../data/match_feed.dart';
import '../data/models.dart';
import '../data/pattern_book.dart';
import '../data/squad.dart';
import '../engine/rational.dart';
import '../engine/strategy.dart';
import '../engine/strength.dart';
import '../engine/strongest_pick.dart';
import '../l10n/copy.dart';

class ChatTurn {
  final String role;
  final String text;
  const ChatTurn({required this.role, required this.text});
}

class AppController extends ChangeNotifier {
  AppController({
    required MatchFeed feed,
    TeamDirectory? squads,
    OpenAiClient? openAi,
    PatternBook? patterns,
  }) : _feed = feed,
       squads = squads ?? TeamDirectory([]),
       _openAi = openAi ?? OpenAiClient(),
       patterns = patterns ?? PatternBook();

  final MatchFeed _feed;
  final TeamDirectory squads;
  final OpenAiClient _openAi;

  List<SportsMatch> matches = [];
  PatternBook patterns;
  bool loading = true;
  String? error;
  Rational stake = defaultStrategyStake;
  final Map<String, String> aiNotes = {};
  bool aiBusy = false;
  final List<ChatTurn> chat = [];
  bool chatBusy = false;
  String? chatError;

  void setStakeInput(String raw) {
    final parsed = parseStakeHuf(raw);
    if (parsed == null || parsed == stake) return;
    stake = parsed;
    notifyListeners();
  }

  BlendedMatch blendedFor(SportsMatch match) {
    final snap = patterns.snapshot(match);
    if (snap.home != null || snap.away != null) {
      return StrengthModel.blendSnapshot(match, snap);
    }
    return StrengthModel.blend(match, squads);
  }

  StrongestPick pickFor(SportsMatch match) =>
      strongestPick(blendedFor(match), hasDraw: match.hasDraw);

  PatternSnapshot patternFor(SportsMatch match) => patterns.snapshot(match);

  StrategyBoard get board {
    final raw = buildStrategy(matches, blendedFor, stake: stake);
    if (aiNotes.isEmpty) {
      return raw.withNotes(const {}, fallback: Copy.aiFallback);
    }
    return raw.withNotes(aiNotes, fallback: Copy.aiFallback);
  }

  String boardContext() {
    final b = board;
    final buf = StringBuffer();
    buf.writeln('Tét: ${formatHuf(b.stake)}');
    buf.writeln('Szelvény lábak:');
    for (final p in b.slip) {
      buf.writeln(
        '- ${p.match.id}: ${p.match.home}–${p.match.away} ${outcomeLabel(p.outcome)} '
        'esély(számítás)=${p.chance.toPercentString()} szorzó=${p.odds.toDecimalString()} '
        'minta=${p.patternLine}',
      );
    }
    buf.writeln('Figyelőlista:');
    for (final p in b.watchlist) {
      buf.writeln(
        '- ${p.match.id}: ${p.match.home}–${p.match.away} ${outcomeLabel(p.outcome)} '
        'esély(számítás)=${p.chance.toPercentString()} minta=${p.patternLine}',
      );
    }
    return buf.toString();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final feed = _feed;
      late List<SportsMatch> list;
      if (feed is LiveSportsFeed) {
        final bundle = await feed.fetchBundle();
        list = bundle.matches;
        patterns = bundle.patterns;
      } else {
        list = [
          ...await feed.upcoming(),
          ...await feed.live(),
        ];
        patterns = PatternBook();
      }
      final seen = <String>{};
      matches = [
        for (final m in list)
          if (seen.add(m.id) && !m.isSample) m,
      ];
    } on FeedException {
      matches = [];
      error = Copy.errorNetwork;
    } catch (_) {
      matches = [];
      error = Copy.errorNetwork;
    } finally {
      loading = false;
      notifyListeners();
    }
    await refreshAiNotes();
  }

  Future<void> refreshAiNotes() async {
    if (matches.isEmpty) return;
    if (!_openAi.isConfigured) {
      aiNotes.clear();
      notifyListeners();
      return;
    }
    aiBusy = true;
    notifyListeners();
    try {
      final b = board;
      if (b.watchlist.isEmpty) {
        aiNotes.clear();
        return;
      }
      final user = StringBuffer()
        ..writeln(boardContext())
        ..writeln(
          'Írj JSON-t: {"notes":[{"id":"...","text":"..."}]} magyarul, '
          'egy rövid mondat meccsenként: mi mozdult (forma/hiányzó/szorzó). '
          'TILOS új százalékot vagy esélyt kitalálni.',
        );
      final raw = await _openAi.complete(
        system:
            'Magyar piaci jegyzetíró. Az esélyt a kliens számolja; te nem adsz %-ot, '
            'nem fogadsz, nem ígérsz nyerést.',
        messages: [(role: 'user', content: user.toString())],
        maxTokens: 700,
      );
      _parseNotes(raw, {for (final p in b.watchlist) p.match.id});
    } on OpenAiException {
      aiNotes.clear();
    } catch (_) {
      aiNotes.clear();
    } finally {
      aiBusy = false;
      notifyListeners();
    }
  }

  void _parseNotes(String raw, Set<String> ids) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return;
    try {
      final decoded = jsonDecode(raw.substring(start, end + 1));
      if (decoded is! Map) return;
      final notes = decoded['notes'];
      if (notes is! List) return;
      for (final item in notes) {
        if (item is! Map) continue;
        final id = item['id']?.toString();
        var text = item['text']?.toString() ?? '';
        if (id == null || !ids.contains(id) || text.isEmpty) continue;
        text = text.replaceAll(RegExp(r'\d+([.,]\d+)?\s*%'), '').trim();
        if (text.isNotEmpty) aiNotes[id] = text;
      }
    } catch (_) {}
  }

  Future<void> sendChat(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || chatBusy) return;
    chatError = null;
    chat.add(ChatTurn(role: 'user', text: trimmed));
    chatBusy = true;
    notifyListeners();
    if (!_openAi.isConfigured) {
      chatBusy = false;
      chatError = Copy.chatNeedKey;
      notifyListeners();
      return;
    }
    try {
      final history = [
        for (final t in chat) (role: t.role, content: t.text),
      ];
      final reply = await _openAi.complete(
        system:
            'Magyar sportfogadási szakértő. A tábla élő számítását magyarázod: '
            'szelvény, figyelőlista, forma, tét. Az esélyt NEM cseréled le, '
            'új %-ot NEM találsz ki, tétet NEM adsz le. Ha valamire nincs adat, mondd meg.',
        messages: [
          (role: 'user', content: 'Jelenlegi tábla:\n${boardContext()}'),
          ...history,
        ],
        maxTokens: 700,
      );
      chat.add(ChatTurn(role: 'assistant', text: reply));
    } on OpenAiException {
      chatError = Copy.chatError;
    } catch (_) {
      chatError = Copy.chatError;
    } finally {
      chatBusy = false;
      notifyListeners();
    }
  }
}
