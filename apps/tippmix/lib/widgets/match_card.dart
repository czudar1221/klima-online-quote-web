import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../engine/rational.dart';
import '../l10n/copy.dart';
import '../theme/app_theme.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.onPick,
    this.onDelete,
    this.selected,
  });

  final SportsMatch match;
  final void Function(Outcome pick)? onPick;
  final VoidCallback? onDelete;
  final Outcome? selected;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('MMM d. HH:mm', 'hu').format(match.kickoff);
    final liveLabel = match.status == MatchStatus.live && match.minute != null
        ? '${match.minute}. ${Copy.minute}'
        : null;
    final score = match.homeScore != null && match.awayScore != null
        ? '${match.homeScore}–${match.awayScore}'
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  match.competition.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.azure,
                  ),
                ),
                const Spacer(),
                _Badge(
                  label: match.isSample ? Copy.sampleBadge : Copy.ownBadge,
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: Copy.delete,
                    onPressed: onDelete,
                    icon: const Icon(Icons.close, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${match.home}  ${Copy.vs}  ${match.away}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              [
                time,
                ?liveLabel,
                ?score,
              ].join('  ·  '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _OddsButton(
                  label: Copy.outcomeHome,
                  odds: match.homeOdds,
                  selected: selected == Outcome.home,
                  onTap: onPick == null ? null : () => onPick!(Outcome.home),
                ),
                const SizedBox(width: 8),
                _OddsButton(
                  label: Copy.outcomeDraw,
                  odds: match.drawOdds,
                  selected: selected == Outcome.draw,
                  onTap: onPick == null ? null : () => onPick!(Outcome.draw),
                ),
                const SizedBox(width: 8),
                _OddsButton(
                  label: Copy.outcomeAway,
                  odds: match.awayOdds,
                  selected: selected == Outcome.away,
                  onTap: onPick == null ? null : () => onPick!(Outcome.away),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _OddsButton extends StatelessWidget {
  const _OddsButton({
    required this.label,
    required this.odds,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Rational odds;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? AppColors.navy : AppColors.mist,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white70 : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  odds.toDecimalString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
