import 'package:flutter/material.dart';

import '../data/models.dart';
import '../engine/rational.dart';
import '../l10n/copy.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/match_card.dart';
import 'app_shell.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final matches = controller.upcoming;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: Copy.matchesTitle,
              subtitle: Copy.matchesHint,
              action: FilledButton.tonal(
                onPressed: () => _openAdd(context),
                child: Text(Copy.addMatch),
              ),
            ),
            Expanded(
              child: controller.loading
                  ? const Center(child: CircularProgressIndicator())
                  : matches.isEmpty
                  ? const EmptyState(message: Copy.emptyMatches)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      itemCount: matches.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final match = matches[i];
                        final selected = controller.slip
                            .where((l) => l.match.id == match.id)
                            .firstOrNull
                            ?.pick;
                        return MatchCard(
                          match: match,
                          selected: selected,
                          onPick: (pick) => controller.addLeg(match, pick),
                          onDelete: match.isSample
                              ? null
                              : () => controller.deleteUserMatch(match.id),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAdd(BuildContext context) async {
    final created = await showModalBottomSheet<SportsMatch>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const AddMatchSheet(),
    );
    if (created != null) {
      await controller.addUserMatch(created);
    }
  }
}

class AddMatchSheet extends StatefulWidget {
  const AddMatchSheet({super.key});

  @override
  State<AddMatchSheet> createState() => _AddMatchSheetState();
}

class _AddMatchSheetState extends State<AddMatchSheet> {
  final _competition = TextEditingController(text: 'NB I');
  final _home = TextEditingController();
  final _away = TextEditingController();
  final _o1 = TextEditingController(text: '2,10');
  final _ox = TextEditingController(text: '3,30');
  final _o2 = TextEditingController(text: '3,40');
  String? _error;
  bool _live = false;

  @override
  void dispose() {
    _competition.dispose();
    _home.dispose();
    _away.dispose();
    _o1.dispose();
    _ox.dispose();
    _o2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + inset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              Copy.addMatchTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _competition,
              decoration: const InputDecoration(labelText: Copy.competition),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _home,
              decoration: const InputDecoration(labelText: Copy.homeTeam),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _away,
              decoration: const InputDecoration(labelText: Copy.awayTeam),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _o1,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: Copy.oddsHome),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ox,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: Copy.oddsDraw),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _o2,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: Copy.oddsAway),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(Copy.live),
              value: _live,
              onChanged: (v) => setState(() => _live = v),
            ),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFB42318)),
              ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _submit, child: const Text(Copy.saveMatch)),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(Copy.cancel),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_home.text.trim().isEmpty || _away.text.trim().isEmpty) {
      setState(() => _error = Copy.errorTeams);
      return;
    }
    try {
      final match = SportsMatch(
        id: 'user-${DateTime.now().microsecondsSinceEpoch}',
        competition: _competition.text.trim().isEmpty
            ? 'NB I'
            : _competition.text.trim(),
        home: _home.text.trim(),
        away: _away.text.trim(),
        kickoff: DateTime.now().add(const Duration(hours: 3)),
        status: _live ? MatchStatus.live : MatchStatus.upcoming,
        minute: _live ? 12 : null,
        homeScore: _live ? 0 : null,
        awayScore: _live ? 0 : null,
        homeOdds: Rational.parseDecimal(_o1.text),
        drawOdds: Rational.parseDecimal(_ox.text),
        awayOdds: Rational.parseDecimal(_o2.text),
        isSample: false,
      );
      match.market;
      Navigator.pop(context, match);
    } catch (_) {
      setState(() => _error = Copy.errorOdds);
    }
  }
}
