import 'package:flutter/material.dart';

import '../data/pattern_book.dart';
import '../data/squad.dart';
import '../engine/rational.dart';
import '../engine/strength.dart';
import '../l10n/copy.dart';
import '../theme/app_theme.dart';

class ChanceBars extends StatelessWidget {
  const ChanceBars({
    super.key,
    required this.chances,
    required this.hasDraw,
  });

  final ThreeWay chances;
  final bool hasDraw;

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, Rational p, Color color})>[
      (label: Copy.outcomeHome, p: chances.home, color: AppColors.navy),
      if (hasDraw)
        (label: Copy.outcomeDraw, p: chances.draw, color: AppColors.azure),
      (label: Copy.outcomeAway, p: chances.away, color: AppColors.navyDeep),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          Copy.modelChanceLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: Text(
                    row.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 14,
                      child: Stack(
                        children: [
                          Container(color: AppColors.accentSoft),
                          FractionallySizedBox(
                            widthFactor: _bar(row.p),
                            child: Container(color: row.color),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 58,
                  child: Text(
                    row.p.toPercentString(),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  double _bar(Rational p) {
    final v = p.toDouble();
    if (v.isNaN || v.isInfinite) return 0;
    if (v < 0) return 0;
    if (v > 1) return 1;
    return v;
  }
}

class FormSpark extends StatelessWidget {
  const FormSpark({super.key, required this.label, required this.form});

  final String label;
  final List<FormResult> form;

  @override
  Widget build(BuildContext context) {
    if (form.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 8),
          for (final r in form.take(8))
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _dot(r),
            ),
        ],
      ),
    );
  }

  Widget _dot(FormResult r) {
    final letter = switch (r) {
      FormResult.win => 'W',
      FormResult.draw => 'D',
      FormResult.loss => 'L',
    };
    final bg = switch (r) {
      FormResult.win => AppColors.navy,
      FormResult.draw => AppColors.azure,
      FormResult.loss => AppColors.mist,
    };
    final fg = r == FormResult.loss ? AppColors.navy : Colors.white;
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.navy),
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class MatchCharts extends StatelessWidget {
  const MatchCharts({
    super.key,
    required this.chances,
    required this.hasDraw,
    required this.snapshot,
  });

  final ThreeWay chances;
  final bool hasDraw;
  final PatternSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChanceBars(chances: chances, hasDraw: hasDraw),
        FormSpark(
          label: '${Copy.homeSide} ${Copy.navForm}',
          form: snapshot.home?.recentForm ?? const [],
        ),
        FormSpark(
          label: '${Copy.awaySide} ${Copy.navForm}',
          form: snapshot.away?.recentForm ?? const [],
        ),
      ],
    );
  }
}
