import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/copy.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: Copy.historyTitle,
              subtitle: Copy.historyHint,
              action: controller.history.isEmpty
                  ? null
                  : TextButton(
                      onPressed: () => _confirmClear(context),
                      child: const Text(Copy.clearHistory),
                    ),
            ),
            Expanded(
              child: controller.history.isEmpty
                  ? const EmptyState(message: Copy.emptyHistory)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      itemCount: controller.history.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final e = controller.history[i];
                        final when = DateFormat(
                          'y. MMMM d. HH:mm',
                          'hu',
                        ).format(e.createdAt);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.percent,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(color: AppColors.navy),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${e.mode} · $when',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                Text(e.summary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(Copy.clearHistory),
        content: const Text(Copy.confirmClear),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(Copy.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(Copy.confirm),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.clearHistory();
    }
  }
}
