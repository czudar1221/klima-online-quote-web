import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../engine/strongest_pick.dart';
import '../l10n/copy.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Copy.appName, style: TextStyle(color: AppColors.muted)),
                      SizedBox(height: 4),
                      Text(
                        Copy.homeTitle,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        Copy.homeHint,
                        style: TextStyle(color: AppColors.muted, height: 1.4),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    Copy.disclaimer,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.navy,
                      height: 1.4,
                    ),
                  ),
                ),
                Expanded(child: _body(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.error != null) {
      return _Message(
        text: controller.error!,
        action: Copy.retry,
        onRetry: controller.load,
      );
    }
    if (controller.matches.isEmpty) {
      return _Message(
        text: Copy.emptyMatches,
        action: Copy.retry,
        onRetry: controller.load,
      );
    }
    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        itemCount: controller.matches.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final match = controller.matches[i];
          return TipMatchCard(
            match: match,
            pick: controller.pickFor(match),
            why: controller.whyFor(match),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.action, required this.onRetry});
  final String text;
  final String action;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: Text(action)),
        ],
      ),
    );
  }
}

class TipMatchCard extends StatelessWidget {
  const TipMatchCard({
    super.key,
    required this.match,
    required this.pick,
    required this.why,
  });

  final SportsMatch match;
  final StrongestPick pick;
  final String why;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm', 'hu').format(match.kickoff);
    final live = match.status == MatchStatus.live;
    final score = match.homeScore != null && match.awayScore != null
        ? '${match.homeScore}–${match.awayScore}'
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${match.sportLabel} · ${match.competition}',
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.azure,
                  ),
                ),
                const Spacer(),
                if (live)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB42318).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      [
                        Copy.live,
                        if (match.minute != null) '${match.minute}. ${Copy.minute}',
                        if (score != null) score,
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB42318),
                      ),
                    ),
                  )
                else
                  Text(time, style: const TextStyle(color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${match.home}  ${Copy.vs}  ${match.away}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Outcome(
                  label: Copy.outcomeHome,
                  chance: pick.chances.home.toPercentString(decimals: 0),
                  selected: pick.outcome == Outcome.home,
                ),
                if (match.hasDraw) ...[
                  const SizedBox(width: 8),
                  _Outcome(
                    label: Copy.outcomeDraw,
                    chance: pick.chances.draw.toPercentString(decimals: 0),
                    selected: pick.outcome == Outcome.draw,
                  ),
                ],
                const SizedBox(width: 8),
                _Outcome(
                  label: Copy.outcomeAway,
                  chance: pick.chances.away.toPercentString(decimals: 0),
                  selected: pick.outcome == Outcome.away,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${Copy.tipp} ${outcomeLabel(pick.outcome)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      Copy.eselyFromOdds,
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                    Text(
                      pick.chance.toPercentString(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              why,
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({
    required this.label,
    required this.chance,
    required this.selected,
  });

  final String label;
  final String chance;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.mist,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white70 : AppColors.muted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              chance,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
