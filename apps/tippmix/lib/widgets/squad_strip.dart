import 'package:flutter/material.dart';

import '../data/squad.dart';
import '../l10n/copy.dart';
import '../theme/app_theme.dart';

class SquadStrip extends StatelessWidget {
  const SquadStrip({super.key, required this.home, required this.away});

  final TeamProfile? home;
  final TeamProfile? away;

  @override
  Widget build(BuildContext context) {
    if (home == null && away == null) {
      return Text(Copy.noRoster, style: Theme.of(context).textTheme.bodySmall);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DataBadge(),
        const SizedBox(height: 8),
        if (home != null) _TeamBlock(team: home!),
        if (home != null && away != null) const SizedBox(height: 10),
        if (away != null) _TeamBlock(team: away!),
      ],
    );
  }
}

class _DataBadge extends StatelessWidget {
  const _DataBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        Copy.curatedBadge,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  const _TeamBlock({required this.team});
  final TeamProfile team;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          team.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '${Copy.formLabel}:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 6),
            for (final r in team.recentForm)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _FormDot(result: r),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${Copy.keyPlayers}: ${team.players.map(_playerLabel).join(' · ')}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _playerLabel(PlayerProfile p) {
    if (p.available) return p.name;
    return '${p.name} (${Copy.unavailable})';
  }
}

class _FormDot extends StatelessWidget {
  const _FormDot({required this.result});
  final FormResult result;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (result) {
      FormResult.win => (Copy.formWin, const Color(0xFF0F766E)),
      FormResult.draw => (Copy.formDrawShort, AppColors.muted),
      FormResult.loss => (Copy.formLoss, const Color(0xFFB42318)),
    };
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
