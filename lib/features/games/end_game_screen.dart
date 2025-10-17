import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/game_scaffold.dart';
import '../../core/team_theme_manager.dart';
import '../../widgets/team_header.dart';

class EndGameScreen extends ConsumerStatefulWidget {
  final int gameId;

  const EndGameScreen({super.key, required this.gameId});

  @override
  ConsumerState<EndGameScreen> createState() => _EndGameScreenState();
}

class _EndGameScreenState extends ConsumerState<EndGameScreen> {
  final _teamScoreController = TextEditingController();
  final _opponentScoreController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  Game? _game;
  Team? _team;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  @override
  void dispose() {
    _teamScoreController.dispose();
    _opponentScoreController.dispose();
    super.dispose();
  }

  Future<void> _loadGame() async {
    final db = ref.read(dbProvider);
    final game = await db.getGame(widget.gameId);
    if (game != null) {
      final team = await db.getTeam(game.teamId);
      setState(() {
        _game = game;
        _team = team;
        // Pre-populate with current scores if they exist
        _teamScoreController.text = game.teamScore.toString();
        _opponentScoreController.text = game.opponentScore.toString();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _completeGame() async {
    if (_game == null) return;

    final teamScore = int.tryParse(_teamScoreController.text.trim()) ?? 0;
    final opponentScore =
        int.tryParse(_opponentScoreController.text.trim()) ?? 0;

    setState(() => _saving = true);

    try {
      final db = ref.read(dbProvider);

      // Update game with final scores and completion status
      await db.updateGame(
        id: widget.gameId,
        teamScore: teamScore,
        opponentScore: opponentScore,
        gameStatus: 'completed',
        endTime: DateTime.now(),
        // Also stop the game timer if it's running
        isGameActive: false,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                teamScore > opponentScore
                    ? Icons.celebration
                    : teamScore < opponentScore
                    ? Icons.sentiment_neutral
                    : Icons.handshake,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                teamScore > opponentScore
                    ? 'Victory! Game completed successfully.'
                    : teamScore < opponentScore
                    ? 'Game completed. Better luck next time!'
                    : 'Draw! Game completed successfully.',
              ),
            ],
          ),
          backgroundColor: teamScore > opponentScore
              ? Colors.green
              : teamScore < opponentScore
              ? Colors.orange
              : Colors.blue,
        ),
      );

      // Navigate back to the game or games list
      if (mounted) {
        context.go('/game/${widget.gameId}');
      }
    } catch (e) {
      if (!mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _getResultText(int teamScore, int opponentScore) {
    if (teamScore > opponentScore) return 'Victory';
    if (teamScore < opponentScore) return 'Defeat';
    return 'Draw';
  }

  Color _getResultColor(int teamScore, int opponentScore) {
    if (teamScore > opponentScore) return Colors.green;
    if (teamScore < opponentScore) return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const GameScaffold(
        gameId: -1,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_game == null) {
      return const Scaffold(body: Center(child: Text('Game not found')));
    }

    final teamName = _team?.name ?? 'Your Team';
    final opponentName = _game!.opponent?.isNotEmpty == true
        ? _game!.opponent!
        : 'Opponent';

    // Preview the result as user types
    final teamScore = int.tryParse(_teamScoreController.text) ?? 0;
    final opponentScore = int.tryParse(_opponentScoreController.text) ?? 0;

    return GameScaffold(
      gameId: _game!.id,
      appBar: const TeamAppBar(titleText: 'End Game'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TeamBrandedHeader(
                teamId: _game!.teamId,
                subtitle: 'Finalize match & scores',
                title: _game!.opponent?.isNotEmpty == true
                    ? 'vs ${_game!.opponent}'
                    : 'Finalize Game',
              ),
            ),
            // Game info header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Final Score',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$teamName vs $opponentName',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Score input section
            Row(
              children: [
                // Team score
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        teamName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _teamScoreController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '0',
                        ),
                        onChanged: (_) => setState(() {}), // Update preview
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // VS divider
                Text(
                  '-',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(width: 24),

                // Opponent score
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        opponentName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _opponentScoreController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '0',
                        ),
                        onChanged: (_) => setState(() {}), // Update preview
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Result preview
            if (_teamScoreController.text.isNotEmpty ||
                _opponentScoreController.text.isNotEmpty) ...[
              Card(
                color: _getResultColor(
                  teamScore,
                  opponentScore,
                ).withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        teamScore > opponentScore
                            ? Icons.celebration_outlined
                            : teamScore < opponentScore
                            ? Icons.sentiment_neutral_outlined
                            : Icons.handshake_outlined,
                        color: _getResultColor(teamScore, opponentScore),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getResultText(teamScore, opponentScore),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: _getResultColor(teamScore, opponentScore),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Spacer(),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _completeGame,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_saving ? 'Completing...' : 'Complete Game'),
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
