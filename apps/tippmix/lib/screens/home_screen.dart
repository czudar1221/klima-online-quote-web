import 'package:flutter/material.dart';

import '../engine/strategy.dart';
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
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (controller.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.error != null) {
              return _Message(
                text: controller.error!,
                onRetry: controller.load,
              );
            }
            if (controller.matches.isEmpty) {
              return _Message(
                text: Copy.emptyMatches,
                onRetry: controller.load,
              );
            }
            final board = controller.board;
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
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
                    Copy.homeTitle,
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
                  const SizedBox(height: 16),
                  _SlipCard(board: board),
                  const SizedBox(height: 20),
                  const Text(
                    Copy.watchlist,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    Copy.notABet,
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (board.watchlist.isEmpty)
                    const Text(
                      Copy.noStrategy,
                      style: TextStyle(color: AppColors.muted),
                    )
                  else
                    ...board.watchlist.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _WatchRow(pick: p),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    Copy.disclaimer,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onRetry});
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

class _SlipCard extends StatelessWidget {
  const _SlipCard({required this.board});
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
              child: Row(
                children: [
                  _Badge(outcomeLabel(p.outcome)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${p.match.home} ${Copy.vs} ${p.match.away}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    p.chance.toPercentString(),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    p.odds.toDecimalString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white24),
          _kv(Copy.stake, formatHuf(strategyStake)),
          _kv(Copy.combinedOdds, board.combinedOdds.toDecimalString()),
          _kv(Copy.combinedChance, board.combinedChance.toPercentString()),
          _kv(Copy.payout, formatHuf(board.slipPayout)),
          _kv(Copy.profit, formatHuf(board.slipProfit), emphasize: true),
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
              '${Copy.profit} ${formatHuf(board.bestSingle!.profit)}',
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

class _Badge extends StatelessWidget {
  const _Badge(this.text);
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

class _WatchRow extends StatelessWidget {
  const _WatchRow({required this.pick});
  final StrategyPick pick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            _Badge(outcomeLabel(pick.outcome)),
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
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${Copy.esely} ${pick.chance.toPercentString()}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                Text(
                  pick.odds.toDecimalString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  '+${formatHuf(pick.profit)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
