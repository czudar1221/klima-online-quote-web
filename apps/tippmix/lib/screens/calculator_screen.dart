import 'package:flutter/material.dart';

import '../data/models.dart';
import '../engine/rational.dart';
import '../engine/strength.dart';
import '../l10n/copy.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/disclaimer_note.dart';
import '../widgets/squad_strip.dart';
import 'app_shell.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final chance = controller.winChance;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const ScreenHeader(
              title: Copy.calculatorTitle,
              subtitle: Copy.appSubtitle,
            ),
            const SizedBox(height: 8),
            SegmentedButton<CalcMode>(
              segments: const [
                ButtonSegment(
                  value: CalcMode.accumulator,
                  label: Text(Copy.modeAccumulator),
                ),
                ButtonSegment(
                  value: CalcMode.combination,
                  label: Text(Copy.modeCombination),
                ),
              ],
              selected: {controller.mode},
              onSelectionChanged: (s) => controller.setMode(s.first),
            ),
            if (controller.mode == CalcMode.combination &&
                controller.slip.length > 1) ...[
              const SizedBox(height: 16),
              Text(
                '${Copy.requiredHits}: ${controller.requiredHits}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                min: 1,
                max: controller.slip.length.toDouble(),
                divisions: controller.slip.length - 1,
                value: controller.requiredHits.toDouble(),
                label: '${controller.requiredHits}',
                onChanged: (v) => controller.setRequiredHits(v.round()),
              ),
            ],
            const SizedBox(height: 12),
            if (controller.slip.isEmpty)
              const EmptyState(message: Copy.emptySlip)
            else
              ...controller.slip.map(
                (leg) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LegTile(
                    leg: leg,
                    blended: controller
                        .blendedFor(leg.match)
                        .blended[leg.pick],
                    onRemove: () => controller.removeLeg(leg.match.id),
                  ),
                ),
              ),
            if (chance != null) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Copy.winChance,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        chance.toPercentString(),
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 16),
                      const DisclaimerNote(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (controller.slip.length == 1)
                _BlendTable(
                  blended: controller.blendedFor(controller.slip.first.match),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: controller.saveCurrentToHistory,
                child: const Text(Copy.saveResult),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: controller.explaining
                    ? null
                    : controller.requestExplanation,
                child: Text(
                  controller.explaining ? Copy.explaining : Copy.explain,
                ),
              ),
              if (controller.explanationRequested &&
                  controller.explanation != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(controller.explanation!),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _LegTile extends StatelessWidget {
  const _LegTile({
    required this.leg,
    required this.blended,
    required this.onRemove,
  });
  final SlipLeg leg;
  final Rational blended;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final pick = switch (leg.pick) {
      Outcome.home => Copy.outcomeHome,
      Outcome.draw => Copy.outcomeDraw,
      Outcome.away => Copy.outcomeAway,
    };
    return Card(
      child: ListTile(
        title: Text('${leg.match.home} ${Copy.vs} ${leg.match.away}'),
        subtitle: Text('$pick · ${Copy.blended} ${blended.toPercentString()}'),
        trailing: IconButton(
          tooltip: Copy.removeLeg,
          onPressed: onRemove,
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}

class _BlendTable extends StatelessWidget {
  const _BlendTable({required this.blended});
  final BlendedMatch blended;

  @override
  Widget build(BuildContext context) {
    final labels = [Copy.outcomeHome, Copy.outcomeDraw, Copy.outcomeAway];
    final market = blended.market;
    final model = blended.model;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Copy.marketBreakdown,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              blended.usedSquads
                  ? '${Copy.blendWeight}: ${blended.modelWeight.toPercentString()}'
                  : Copy.marketOnly,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 22, child: Text(labels[i])),
                    Expanded(
                      child: Text(
                        '${Copy.fair} ${market.fair[i].toPercentString()}'
                        '${model == null ? '' : '  ·  ${Copy.modelOnly} ${model.asList[i].toPercentString()}'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      blended.blended.asList[i].toPercentString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(),
            Text(
              '${Copy.overround} ${market.overround.toDecimalString(decimals: 4)}  ·  '
              '${Copy.margin} ${market.margin.toPercentString()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              Copy.formulaTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              Copy.formulaNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SquadStrip(
              home: blended.homeProfile,
              away: blended.awayProfile,
            ),
          ],
        ),
      ),
    );
  }
}
