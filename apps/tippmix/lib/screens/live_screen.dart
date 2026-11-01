import 'package:flutter/material.dart';

import '../l10n/copy.dart';
import '../state/app_controller.dart';
import '../widgets/match_card.dart';
import 'app_shell.dart';

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final matches = controller.live;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenHeader(
              title: Copy.liveTitle,
              subtitle: Copy.liveHint,
            ),
            Expanded(
              child: controller.loading
                  ? const Center(child: CircularProgressIndicator())
                  : matches.isEmpty
                  ? const EmptyState(message: Copy.emptyLive)
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
                          homeProfile: controller.squads.find(
                            id: match.homeTeamId,
                            name: match.home,
                          ),
                          awayProfile: controller.squads.find(
                            id: match.awayTeamId,
                            name: match.away,
                          ),
                          onPick: (pick) => controller.addLeg(match, pick),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
