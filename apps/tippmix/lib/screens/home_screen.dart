import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/pattern_book.dart';
import '../engine/rational.dart';
import '../engine/strategy.dart';
import '../engine/strongest_pick.dart';
import '../l10n/copy.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'chance_charts.dart';

class SlipPage extends StatelessWidget {
  const SlipPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final board = controller.board;
    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        key: const Key('boardList'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Text(
            Copy.appName,
            style: TextStyle(
              color: AppColors.muted,
              letterSpacing: 1.2,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            Copy.bestSlip,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Copy.statusLine(
              matches: board.matchCount,
              live: board.liveMatchCount,
              tips: board.watchlist.length,
            ),
            style: const TextStyle(
              color: AppColors.azure,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            Copy.homeHint,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 4),
          const Text(
            Copy.formulaChecked,
            style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 16),
          StakeCard(controller: controller),
          const SizedBox(height: 16),
          SlipCard(board: board),
          const SizedBox(height: 12),
          const Text(
            Copy.disclaimer,
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class StakeCard extends StatefulWidget {
  const StakeCard({super.key, required this.controller});
  final AppController controller;

  @override
  State<StakeCard> createState() => _StakeCardState();
}

class _StakeCardState extends State<StakeCard> {
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    final n = widget.controller.stake.n;
    _text = TextEditingController(text: n.toString());
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              Copy.stakeFt,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              Copy.stakeHint,
              style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('stakeFt'),
              controller: _text,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9 \u00a0]')),
              ],
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.navy,
              ),
              decoration: const InputDecoration(
                suffixText: 'Ft',
                suffixStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              onChanged: widget.controller.setStakeInput,
            ),
          ],
        ),
      ),
    );
  }
}

class BoardMessage extends StatelessWidget {
  const BoardMessage({super.key, required this.text, required this.onRetry});
  final String text;
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
          FilledButton(onPressed: onRetry, child: const Text(Copy.retry)),
        ],
      ),
    );
  }
}

class SlipCard extends StatelessWidget {
  const SlipCard({super.key, required this.board});
  final StrategyBoard board;

  @override
  Widget build(BuildContext context) {
    if (board.slip.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            Copy.noStrategy,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            Copy.bestSlip,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ...board.slip.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SlipLegRow(pick: p),
            ),
          ),
          const Divider(color: Colors.white24),
          _kv(Copy.stake, formatHuf(board.stake)),
          _kv(Copy.combinedOdds, board.combinedOdds.toDecimalString()),
          _kv(Copy.combinedChance, board.combinedChance.toPercentString()),
          _kv(Copy.payout, formatHuf(board.slipPayout)),
          _kv(Copy.profit, formatHuf(board.slipProfit), emphasize: true),
          _kv(Copy.suggestedStake, formatHuf(board.suggestedStake)),
          const SizedBox(height: 8),
          const Text(
            Copy.suggestedHint,
            style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 8),
          const Text(
            Copy.independence,
            style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.35),
          ),
          if (board.bestSingle != null) ...[
            const SizedBox(height: 12),
            Text(
              '${Copy.bestSingle}: ${outcomeLabel(board.bestSingle!.outcome)}  '
              '${board.bestSingle!.match.home} ${Copy.vs} ${board.bestSingle!.match.away}  ·  '
              '${Copy.profit} ${formatHuf(board.bestSingle!.profitOn(board.stake))}',
              style: const TextStyle(color: Colors.white, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(k, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(
            v,
            style: TextStyle(
              color: Colors.white,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              fontSize: emphasize ? 20 : 15,
            ),
          ),
        ],
      ),
    );
  }
}

class OutcomeBadge extends StatelessWidget {
  const OutcomeBadge(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SlipLegRow extends StatefulWidget {
  const _SlipLegRow({required this.pick});
  final StrategyPick pick;

  @override
  State<_SlipLegRow> createState() => _SlipLegRowState();
}

class _SlipLegRowState extends State<_SlipLegRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final pick = widget.pick;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Row(
            children: [
              OutcomeBadge(outcomeLabel(pick.outcome)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pick.match.home} ${Copy.vs} ${pick.match.away}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _open
                          ? '${pick.patternLine} · ${pick.valueLine}'
                          : Copy.chartTap,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                pick.chance.toPercentString(),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 8),
              Text(
                pick.odds.toDecimalString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Icon(
                _open ? Icons.expand_less : Icons.expand_more,
                color: Colors.white70,
                size: 22,
              ),
            ],
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 8),
          MatchCharts(
            chances: pick.chances,
            hasDraw: pick.match.hasDraw,
            snapshot: PatternBook().snapshot(pick.match),
          ),
        ],
      ],
    );
  }
}

class WatchRow extends StatefulWidget {
  const WatchRow({
    super.key,
    required this.pick,
    required this.stake,
    this.snapshot,
  });
  final StrategyPick pick;
  final Rational stake;
  final PatternSnapshot? snapshot;

  @override
  State<WatchRow> createState() => _WatchRowState();
}

class _WatchRowState extends State<WatchRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final pick = widget.pick;
    final snap = widget.snapshot ?? PatternBook().snapshot(pick.match);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  OutcomeBadge(outcomeLabel(pick.outcome)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pick.match.sportLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.azure,
                          ),
                        ),
                        Text(
                          '${pick.match.home} ${Copy.vs} ${pick.match.away}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          pick.patternLine,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          pick.valueLine,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${Copy.modelChanceLabel} ${pick.chance.toPercentString()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        pick.odds.toDecimalString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        '+${formatHuf(pick.profitOn(widget.stake))}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.navy,
                  ),
                ],
              ),
              if (!_open)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    Copy.chartTap,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.azure,
                    ),
                  ),
                ),
              if (_open) ...[
                const SizedBox(height: 10),
                MatchCharts(
                  chances: pick.chances,
                  hasDraw: pick.match.hasDraw,
                  snapshot: snap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
