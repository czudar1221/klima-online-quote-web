import 'package:flutter/material.dart';

import '../data/models.dart';
import '../engine/strongest_pick.dart';
import '../l10n/copy.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            if (c.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (c.error != null) {
              return BoardMessage(text: c.error!, onRetry: c.load);
            }
            if (c.matches.isEmpty && _index != 4) {
              return BoardMessage(text: Copy.emptyMatches, onRetry: c.load);
            }
            return IndexedStack(
              index: _index,
              children: [
                SlipPage(controller: c),
                _WatchPage(controller: c),
                _FormPage(controller: c),
                _AiPage(controller: c),
                _ChatPage(controller: c),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: Copy.bestSlip,
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: Copy.watchlist,
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: Copy.navForm,
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: Copy.navAi,
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: Copy.navChat,
          ),
        ],
      ),
    );
  }
}

class _WatchPage extends StatelessWidget {
  const _WatchPage({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final board = controller.board;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Text(
          Copy.watchlist,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          Copy.notABet,
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 4),
        const Text(
          Copy.formulaChecked,
          style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (board.watchlist.isEmpty)
          const Text(Copy.noStrategy, style: TextStyle(color: AppColors.muted))
        else
          ...board.watchlist.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: WatchRow(pick: p, stake: board.stake),
            ),
          ),
      ],
    );
  }
}

class _FormPage extends StatelessWidget {
  const _FormPage({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Text(
          Copy.navForm,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          Copy.formPageHint,
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        for (final match in controller.matches)
          _FormCard(controller: controller, match: match),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.controller, required this.match});
  final AppController controller;
  final SportsMatch match;

  @override
  Widget build(BuildContext context) {
    final snap = controller.patternFor(match);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${match.sportLabel} · ${match.home} ${Copy.vs} ${match.away}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Text('${Copy.homeSide} · ${match.home}: ${snap.formLabel(true)}'),
              Text('${Copy.patternAbsence}: ${snap.absenceLabel(true)}'),
              const SizedBox(height: 6),
              Text('${Copy.awaySide} · ${match.away}: ${snap.formLabel(false)}'),
              Text('${Copy.patternAbsence}: ${snap.absenceLabel(false)}'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiPage extends StatelessWidget {
  const _AiPage({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final board = controller.board;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Text(
          Copy.navAi,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          Copy.aiPageHint,
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        if (controller.aiBusy) const LinearProgressIndicator(),
        const SizedBox(height: 16),
        if (board.watchlist.isEmpty)
          const Text(Copy.noStrategy, style: TextStyle(color: AppColors.muted))
        else
          ...board.watchlist.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${outcomeLabel(p.outcome)}  ${p.match.home} ${Copy.vs} ${p.match.away}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        '${Copy.modelChanceLabel}: ${p.chance.toPercentString()} · ${p.valueLine} · ${p.patternLine}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.aiNote.isEmpty ? Copy.aiFallback : p.aiNote,
                        style: const TextStyle(height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChatPage extends StatefulWidget {
  const _ChatPage({required this.controller});
  final AppController controller;

  @override
  State<_ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<_ChatPage> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            children: [
              const Text(
                Copy.chatTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                Copy.chatHint,
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
              if (c.chatError != null) ...[
                const SizedBox(height: 10),
                Text(
                  c.chatError!,
                  style: const TextStyle(color: Color(0xFFB42318)),
                ),
              ],
              const SizedBox(height: 16),
              for (final turn in c.chat)
                Align(
                  alignment: turn.role == 'user'
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      turn.text,
                      style: const TextStyle(
                        color: Colors.black,
                        height: 1.4,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('chatInput'),
                  controller: _input,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  cursorColor: Colors.black,
                  decoration: const InputDecoration(
                    hintText: Copy.chatTitle,
                    hintStyle: TextStyle(color: Color(0xFF5C6B80)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: c.chatBusy ? null : _send,
                child: Text(c.chatBusy ? '…' : Copy.chatSend),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _send() async {
    final text = _input.text;
    _input.clear();
    await widget.controller.sendChat(text);
  }
}
