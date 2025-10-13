import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class LineupBuilderScreen extends ConsumerWidget {
  final int gameId;
  const LineupBuilderScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Lineup Builder')),
      body: FutureBuilder<Game?>(
        future: db.getGame(gameId),
        builder: (context, gSnap) {
          final game = gSnap.data;
          if (game == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return FutureBuilder<List<Player>>(
            future: db.presentPlayersForGame(gameId, game.teamId),
            builder: (context, pSnap) {
              if (!pSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final present = pSnap.data!;
              return _Formations(
                present: present,
                onApply: (positions) async {
                  debugPrint('\n=== LINEUP BUILDER USING FAIR ASSIGNMENT ===');
                  debugPrint(
                    'Creating initial shift using createAutoShift algorithm',
                  );

                  // Use the same fair assignment algorithm as other shifts
                  await db.createAutoShift(
                    gameId: gameId,
                    startSeconds: 0,
                    positions: positions,
                    activate: true,
                  );

                  debugPrint(
                    'Initial shift created with fair assignment algorithm',
                  );
                  debugPrint('=== LINEUP BUILDER COMPLETE ===\n');
                  if (context.mounted) Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _Formations extends StatefulWidget {
  final List<Player> present;
  final Future<void> Function(List<String> positions) onApply;
  const _Formations({required this.present, required this.onApply});

  @override
  State<_Formations> createState() => _FormationsState();
}

class _FormationsState extends State<_Formations> {
  String _formation = '2-3-1';

  List<String> get _positions {
    switch (_formation) {
      case '3-2-1':
        return [
          'GOALIE',
          'RIGHT_DEFENSE',
          'LEFT_DEFENSE',
          'CENTER_FORWARD',
          'RIGHT_FORWARD',
          'LEFT_FORWARD',
        ];
      case '2-2-2':
        return [
          'GOALIE',
          'RIGHT_DEFENSE',
          'LEFT_DEFENSE',
          'CENTER_FORWARD',
          'RIGHT_FORWARD',
          'LEFT_FORWARD',
        ];
      case '2-3-1':
      default:
        return [
          'GOALIE',
          'RIGHT_DEFENSE',
          'LEFT_DEFENSE',
          'CENTER_FORWARD',
          'RIGHT_FORWARD',
          'LEFT_FORWARD',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final positions = _positions;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Present players: ${widget.present.length}',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 12),
          DropdownButton<String>(
            value: _formation,
            items: const [
              DropdownMenuItem(value: '2-3-1', child: Text('2-3-1')),
              DropdownMenuItem(value: '3-2-1', child: Text('3-2-1')),
              DropdownMenuItem(value: '2-2-2', child: Text('2-2-2')),
            ],
            onChanged: (v) => setState(() => _formation = v!),
          ),
          const SizedBox(height: 16),
          Text(
            'Will assign first ${positions.length} present players to:',
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: positions.map((p) => Chip(label: Text(p))).toList(),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => widget.onApply(positions),
            child: const Text('Apply to new shift'),
          ),
        ],
      ),
    );
  }
}
