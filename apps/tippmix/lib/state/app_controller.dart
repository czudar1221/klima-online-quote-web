import 'package:flutter/foundation.dart';

import '../ai/openai_explainer.dart';
import '../data/curated_squads.dart';
import '../data/local_store.dart';
import '../data/match_feed.dart';
import '../data/models.dart';
import '../data/squad.dart';
import '../engine/probability.dart';
import '../engine/rational.dart';
import '../engine/strength.dart';
import '../l10n/copy.dart';

enum CalcMode { accumulator, combination }

class AppController extends ChangeNotifier {
  AppController({
    required MatchFeed feed,
    required LocalStore store,
    TeamDirectory? squads,
    OpenAiExplainer? explainer,
  }) : _feed = feed,
       _store = store,
       squads = squads ?? curatedHungarianSquads(),
       _explainer = explainer ?? OpenAiExplainer();

  final MatchFeed _feed;
  final LocalStore _store;
  final TeamDirectory squads;
  final OpenAiExplainer _explainer;

  List<SportsMatch> sampleUpcoming = [];
  List<SportsMatch> sampleLive = [];
  List<SportsMatch> userMatches = [];
  List<HistoryEntry> history = [];
  List<SlipLeg> slip = [];
  CalcMode mode = CalcMode.accumulator;
  int requiredHits = 1;
  bool loading = true;
  String? error;
  String? explanation;
  bool explaining = false;
  bool explanationRequested = false;

  List<SportsMatch> get upcoming {
    final all = [...sampleUpcoming, ...userMatches];
    all.sort((a, b) => a.kickoff.compareTo(b.kickoff));
    return all;
  }

  List<SportsMatch> get live {
    final extra = userMatches
        .where((m) => m.status == MatchStatus.live)
        .toList();
    return [...sampleLive, ...extra];
  }

  BlendedMatch blendedFor(SportsMatch match) =>
      StrengthModel.blend(match, squads);

  IndependentEvents? get events {
    if (slip.isEmpty) return null;
    return IndependentEvents([
      for (final leg in slip) blendedFor(leg.match).blended[leg.pick],
    ]);
  }

  Rational? get winChance {
    final e = events;
    if (e == null) return null;
    if (mode == CalcMode.accumulator) {
      return e.accumulator;
    }
    return e.probabilityAtLeast(requiredHits.clamp(1, slip.length));
  }

  String get slipSummary {
    if (slip.isEmpty) return Copy.emptySlip;
    return slip
        .map((leg) {
          final pick = switch (leg.pick) {
            Outcome.home => Copy.outcomeHome,
            Outcome.draw => Copy.outcomeDraw,
            Outcome.away => Copy.outcomeAway,
          };
          return '${leg.match.home} ${Copy.vs} ${leg.match.away} ($pick)';
        })
        .join(' · ');
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _feed.upcoming(),
        _feed.live(),
        _store.loadUserMatches(),
        _store.loadHistory(),
      ]);
      sampleUpcoming = results[0] as List<SportsMatch>;
      sampleLive = results[1] as List<SportsMatch>;
      userMatches = results[2] as List<SportsMatch>;
      history = results[3] as List<HistoryEntry>;
    } catch (_) {
      error = Copy.errorGeneric;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setMode(CalcMode next) {
    mode = next;
    if (mode == CalcMode.combination && slip.isNotEmpty) {
      requiredHits = requiredHits.clamp(1, slip.length);
    }
    explanation = null;
    explanationRequested = false;
    notifyListeners();
  }

  void setRequiredHits(int value) {
    if (slip.isEmpty) return;
    requiredHits = value.clamp(1, slip.length);
    explanation = null;
    explanationRequested = false;
    notifyListeners();
  }

  void addLeg(SportsMatch match, Outcome pick) {
    slip = [
      ...slip.where((l) => l.match.id != match.id),
      SlipLeg(match: match, pick: pick),
    ];
    if (requiredHits > slip.length) requiredHits = slip.length;
    if (requiredHits < 1) requiredHits = 1;
    explanation = null;
    explanationRequested = false;
    notifyListeners();
  }

  void removeLeg(String matchId) {
    slip = [for (final l in slip) if (l.match.id != matchId) l];
    if (slip.isEmpty) {
      requiredHits = 1;
    } else {
      requiredHits = requiredHits.clamp(1, slip.length);
    }
    explanation = null;
    explanationRequested = false;
    notifyListeners();
  }

  Future<void> addUserMatch(SportsMatch match) async {
    userMatches = [...userMatches, match];
    await _store.saveUserMatches(userMatches);
    notifyListeners();
  }

  Future<void> deleteUserMatch(String id) async {
    userMatches = [for (final m in userMatches) if (m.id != id) m];
    slip = [for (final l in slip) if (l.match.id != id) l];
    await _store.saveUserMatches(userMatches);
    notifyListeners();
  }

  Future<void> saveCurrentToHistory() async {
    final chance = winChance;
    if (chance == null) return;
    final entry = HistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      summary: slipSummary,
      percent: chance.toPercentString(),
      mode: mode == CalcMode.accumulator
          ? Copy.modeAccumulator
          : Copy.modeCombination,
      requiredHits: mode == CalcMode.accumulator
          ? slip.length
          : requiredHits,
    );
    history = [entry, ...history];
    await _store.saveHistory(history);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    history = [];
    await _store.saveHistory(history);
    notifyListeners();
  }

  Future<void> requestExplanation() async {
    final chance = winChance;
    if (chance == null) return;
    explaining = true;
    explanationRequested = true;
    notifyListeners();
    explanation = await _explainer.explain(
      winChance: chance,
      summary: slipSummary,
      isAccumulator: mode == CalcMode.accumulator,
      requiredHits: mode == CalcMode.accumulator ? slip.length : requiredHits,
      legCount: slip.length,
      blendNote: slip
          .map((leg) {
            final b = blendedFor(leg.match);
            return '${leg.match.home}–${leg.match.away}: '
                'piac ${b.market.fair[0].toPercentString()}/'
                '${b.market.fair[1].toPercentString()}/'
                '${b.market.fair[2].toPercentString()}'
                '${b.model == null ? '' : ', modell ${b.model!.home.toPercentString()}/${b.model!.draw.toPercentString()}/${b.model!.away.toPercentString()}'}'
                ', kevert ${b.blended.home.toPercentString()}/${b.blended.draw.toPercentString()}/${b.blended.away.toPercentString()}';
          })
          .join('\n'),
    );
    explaining = false;
    notifyListeners();
  }
}
