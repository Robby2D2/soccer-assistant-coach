import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers.dart';

class TraditionalGameScreen extends ConsumerStatefulWidget {
  final int gameId;
  const TraditionalGameScreen({super.key, required this.gameId});
  @override
  ConsumerState<TraditionalGameScreen> createState() =>
      _TraditionalGameScreenState();
}

class _TraditionalGameScreenState extends ConsumerState<TraditionalGameScreen> {
  late final ValueNotifier<int> _gameTimeNotifier;
  late final ValueNotifier<bool> _isRunningNotifier;
  late final ValueNotifier<int> _currentHalfNotifier;
  Timer? _gameTimer;
  int _halfDurationSeconds = 1200; // 20 minutes default

  // Current lineup tracking
  final Map<String, int> _currentLineup = {}; // position -> playerId
  final Map<int, int> _playingTimeThisGame = {}; // playerId -> seconds
  final Map<int, int> _lastSavedPlayingTime = {}; // playerId -> seconds

  bool get _isRunning => _isRunningNotifier.value;
  set _isRunning(bool value) => _isRunningNotifier.value = value;

  int get _gameTime => _gameTimeNotifier.value;
  set _gameTime(int value) => _gameTimeNotifier.value = value;

  int get _currentHalf => _currentHalfNotifier.value;
  set _currentHalf(int value) => _currentHalfNotifier.value = value;

  @override
  void initState() {
    super.initState();
    _gameTimeNotifier = ValueNotifier<int>(0);
    _isRunningNotifier = ValueNotifier<bool>(false);
    _currentHalfNotifier = ValueNotifier<int>(1);
    _loadGameState();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    // Note: No need to save playing time here since we have:
    // 1. Periodic auto-saving every 30 seconds
    // 2. Save on pause/timer stop
    // 3. ref.read() is not available during dispose
    _gameTimeNotifier.dispose();
    _isRunningNotifier.dispose();
    _currentHalfNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadGameState() async {
    final db = ref.read(dbProvider);
    final game = await db.getGame(widget.gameId);

    if (game != null) {
      _gameTimeNotifier.value = game.gameTimeSeconds;
      _currentHalfNotifier.value = game.currentHalf;
      _isRunning = game.isGameActive;

      // Load team's configured half duration
      _halfDurationSeconds = await db.getTeamHalfDurationSeconds(game.teamId);

      // Load existing playing times for this game
      final savedPlayingTimes = await db.getTraditionalPlayingTimeByPlayer(
        widget.gameId,
      );
      _playingTimeThisGame.clear();
      _playingTimeThisGame.addAll(savedPlayingTimes);
      // Track what has already been saved to avoid double-counting
      _lastSavedPlayingTime.clear();
      _lastSavedPlayingTime.addAll(savedPlayingTimes);

      // Auto-populate lineup if it's empty
      if (_currentLineup.isEmpty) {
        await _autoPopulateLineup(game.teamId);
      }
    }
  }

  Future<void> _autoPopulateLineup(int teamId) async {
    final db = ref.read(dbProvider);

    // First try to get lineup from most recent completed game
    final recentGame = await db.getMostRecentCompletedGame(
      teamId,
      widget.gameId,
    );
    if (recentGame != null) {
      final previousLineup = await db.getTraditionalLineupFromGame(
        recentGame.id,
      );
      if (previousLineup != null && previousLineup.isNotEmpty) {
        // Verify all players are still available for this game
        final availablePlayers =
            await (db.select(db.gamePlayers)..where(
                  (gp) =>
                      gp.gameId.equals(widget.gameId) &
                      gp.isPresent.equals(true),
                ))
                .get();
        final availablePlayerIds = availablePlayers
            .map((gp) => gp.playerId)
            .toSet();

        // Only use positions where players are still available
        final validLineup = <String, int>{};
        for (final entry in previousLineup.entries) {
          if (availablePlayerIds.contains(entry.value)) {
            validLineup[entry.key] = entry.value;
          }
        }

        if (validLineup.isNotEmpty) {
          setState(() {
            _currentLineup.clear();
            _currentLineup.addAll(validLineup);
            // Initialize last saved time to avoid double-counting
            for (final playerId in validLineup.values) {
              _lastSavedPlayingTime[playerId] =
                  _playingTimeThisGame[playerId] ?? 0;
            }
          });
          return;
        }
      }
    }

    // Fallback: Generate random lineup based on game's formation
    final game = await db.getGame(widget.gameId);
    if (game != null) {
      // Use the game's selected formation, or fall back to most used formation
      var formationId = game.formationId;
      formationId ??= await db.mostUsedFormationIdForTeam(teamId);

      if (formationId != null) {
        final randomLineup = await db.generateRandomLineup(
          gameId: widget.gameId,
          formationId: formationId,
        );
        if (randomLineup.isNotEmpty) {
          setState(() {
            _currentLineup.clear();
            _currentLineup.addAll(randomLineup);
            // Initialize last saved time for randomly generated players
            for (final playerId in randomLineup.values) {
              _lastSavedPlayingTime[playerId] =
                  _playingTimeThisGame[playerId] ?? 0;
            }
          });
        }
      }
    }
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }

      setState(() {
        _gameTime = _gameTime + 1;
      });

      // Update playing time for current lineup
      for (final playerId in _currentLineup.values) {
        _playingTimeThisGame[playerId] =
            (_playingTimeThisGame[playerId] ?? 0) + 1;
      }

      // Auto-save playing time every 30 seconds
      if (_gameTime % 30 == 0) {
        _savePlayingTime();
      }

      // Save game time to database
      final db = ref.read(dbProvider);
      db.updateGameTime(widget.gameId, _gameTime);
    });
  }

  void _pauseTimer() {
    _gameTimer?.cancel();
    setState(() {
      _isRunning = false;
    });
    final db = ref.read(dbProvider);
    db.pauseGameTimer(widget.gameId);
    // Save playing time when pausing
    _savePlayingTime();
  }

  void _startOrResumeTimer() async {
    setState(() {
      _isRunning = true;
    });
    final db = ref.read(dbProvider);
    await db.startGameTimer(widget.gameId);

    // Save current lineup when starting the game
    if (_currentLineup.isNotEmpty) {
      await db.saveTraditionalLineup(
        gameId: widget.gameId,
        lineup: _currentLineup,
      );
    }

    _startTimer();
  }

  Future<void> _resetTimer() async {
    _gameTimer?.cancel();
    setState(() {
      _gameTime = 0;
      _isRunning = false;
      _currentHalf = 1;
      _playingTimeThisGame.clear();
    });
    final db = ref.read(dbProvider);
    await db.resetGameTimer(widget.gameId);

    // Clear playing time for this game
    await db.customUpdate(
      'DELETE FROM player_metrics WHERE game_id = ? AND metric = ?',
      variables: [
        drift.Variable<int>(widget.gameId),
        drift.Variable<String>('traditional_playing_time'),
      ],
    );
  }

  Future<void> _startSecondHalf() async {
    // Check if first half is complete
    if (_gameTime < _halfDurationSeconds) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start Second Half?'),
          content: Text(
            'The first half timer shows ${_formatTime(_halfDurationSeconds - _gameTime)} remaining. '
            'Are you sure you want to start the second half?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Start Second Half'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) return;
    }

    // Save playing time for first half
    await _savePlayingTime();

    // Start second half
    _pauseTimer();
    setState(() {
      _currentHalf = 2;
      _gameTime = 0; // Reset timer for second half
      // Don't clear _playingTimeThisHalf - keep accumulating total game time
    });

    final db = ref.read(dbProvider);
    await db.startSecondHalf(widget.gameId);
    await db.updateGameTime(widget.gameId, 0);
  }

  Future<void> _savePlayingTime() async {
    final db = ref.read(dbProvider);
    for (final entry in _playingTimeThisGame.entries) {
      final playerId = entry.key;
      final currentTime = entry.value;
      final lastSaved = _lastSavedPlayingTime[playerId] ?? 0;
      final incrementalTime = currentTime - lastSaved;

      if (incrementalTime > 0) {
        await db.updateTraditionalPlayingTime(
          gameId: widget.gameId,
          playerId: playerId,
          position: _getPlayerPosition(playerId) ?? 'Unknown',
          seconds: incrementalTime,
        );
        // Update the last saved time
        _lastSavedPlayingTime[playerId] = currentTime;
      }
    }
  }

  String? _getPlayerPosition(int playerId) {
    for (final entry in _currentLineup.entries) {
      if (entry.value == playerId) return entry.key;
    }
    return null;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$year-$month-$day • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Game?>(
          future: db.getGame(widget.gameId),
          builder: (context, snap) {
            final game = snap.data;
            final title = (game?.opponent?.isNotEmpty == true)
                ? game!.opponent!
                : 'Game';
            final subtitle = game?.startTime == null
                ? null
                : _formatDateTime(game!.startTime!);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          PopupMenuButton<_TraditionalGameMenuAction>(
            onSelected: (value) async {
              switch (value) {
                case _TraditionalGameMenuAction.edit:
                  if (!context.mounted) return;
                  context.push('/game/${widget.gameId}/edit');
                  break;
                case _TraditionalGameMenuAction.metricsView:
                  if (!context.mounted) return;
                  context.push('/game/${widget.gameId}/metrics');
                  break;
                case _TraditionalGameMenuAction.metricsInput:
                  if (!context.mounted) return;
                  context.push('/game/${widget.gameId}/metrics/input');
                  break;
                case _TraditionalGameMenuAction.attendance:
                  if (!context.mounted) return;
                  context.push('/game/${widget.gameId}/attendance');
                  break;
                case _TraditionalGameMenuAction.reset:
                  await _resetTimer();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _TraditionalGameMenuAction.edit,
                child: Text('Edit game'),
              ),
              PopupMenuItem(
                value: _TraditionalGameMenuAction.metricsView,
                child: Text('View Metrics'),
              ),
              PopupMenuItem(
                value: _TraditionalGameMenuAction.metricsInput,
                child: Text('Input Metrics'),
              ),
              PopupMenuItem(
                value: _TraditionalGameMenuAction.attendance,
                child: Text('Attendance'),
              ),
              PopupMenuItem(
                value: _TraditionalGameMenuAction.reset,
                child: Text('Reset timer'),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Game?>(
        future: db.getGame(widget.gameId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final game = snap.data!;
          return StreamBuilder<List<Player>>(
            stream: db.watchPlayersByTeam(game.teamId),
            builder: (context, playersSnap) {
              if (!playersSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final players = playersSnap.data!;
              final playersById = {for (final p in players) p.id: p};

              return Column(
                children: [
                  const SizedBox(height: 12),

                  // Half and Timer Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ValueListenableBuilder<int>(
                            valueListenable: _currentHalfNotifier,
                            builder: (context, half, _) => Text(
                              half == 1 ? 'First Half' : 'Second Half',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ),
                        ),
                        if (_currentHalf == 1)
                          FilledButton.icon(
                            icon: const Icon(Icons.skip_next),
                            label: const Text('Second Half'),
                            onPressed: _startSecondHalf,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Game Progress Timeline
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ValueListenableBuilder<int>(
                      valueListenable: _gameTimeNotifier,
                      builder: (context, gameTime, _) =>
                          ValueListenableBuilder<int>(
                            valueListenable: _currentHalfNotifier,
                            builder: (context, currentHalf, _) =>
                                _GameProgressTimeline(
                                  currentHalf: currentHalf,
                                  gameTime: gameTime,
                                  halfDurationSeconds: _halfDurationSeconds,
                                ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Timer Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ValueListenableBuilder<int>(
                      valueListenable: _gameTimeNotifier,
                      builder: (context, gameTime, _) {
                        final remaining = _halfDurationSeconds - gameTime;
                        final over = remaining <= 0;
                        final flashOn = over && (((-remaining) ~/ 2) % 2 == 0);
                        final theme = Theme.of(context);
                        final baseline =
                            theme.colorScheme.surfaceContainerHighest;
                        final panelColor = over
                            ? (flashOn ? Colors.red.shade800 : baseline)
                            : baseline;

                        return Card(
                          color: panelColor,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Text(
                                  over
                                      ? '+${_formatTime(-remaining)}'
                                      : _formatTime(remaining),
                                  key: ValueKey(remaining),
                                  style: theme.textTheme.displayMedium
                                      ?.copyWith(
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                        letterSpacing: 2.0,
                                        fontWeight: FontWeight.w300,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Start/Pause Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _isRunningNotifier,
                      builder: (context, isRunning, _) => OverflowBar(
                        alignment: MainAxisAlignment.center,
                        children: [
                          if (!isRunning)
                            FilledButton.icon(
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Start'),
                              onPressed: _startOrResumeTimer,
                            )
                          else
                            FilledButton.icon(
                              icon: const Icon(Icons.pause_rounded),
                              label: const Text('Pause'),
                              onPressed: _pauseTimer,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Divider(),
                  ),

                  // Players Section
                  Expanded(
                    child: _TraditionalLineupView(
                      gameId: widget.gameId,
                      players: players,
                      playersById: playersById,
                      currentLineup: _currentLineup,
                      playingTimeThisGame: _playingTimeThisGame,
                      onPlayerSubstitution: (outPlayerId, inPlayerId, position) {
                        setState(() {
                          if (outPlayerId != null) {
                            _currentLineup.remove(
                              _getPlayerPosition(outPlayerId),
                            );
                          }
                          if (inPlayerId != null && position != null) {
                            _currentLineup[position] = inPlayerId;
                            // Initialize last saved time to current time to avoid double-counting
                            _lastSavedPlayingTime[inPlayerId] =
                                _playingTimeThisGame[inPlayerId] ?? 0;
                          }
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TraditionalLineupView extends StatelessWidget {
  final int gameId;
  final List<Player> players;
  final Map<int, Player> playersById;
  final Map<String, int> currentLineup;
  final Map<int, int> playingTimeThisGame;
  final Function(int? outPlayerId, int? inPlayerId, String? position)
  onPlayerSubstitution;

  const _TraditionalLineupView({
    required this.gameId,
    required this.players,
    required this.playersById,
    required this.currentLineup,
    required this.playingTimeThisGame,
    required this.onPlayerSubstitution,
  });

  String _formatPlayingTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Separate active players from bench players
    final activePlayerIds = currentLineup.values.toSet();
    final activePlayers = players
        .where((p) => activePlayerIds.contains(p.id))
        .toList();
    final benchPlayers = players
        .where((p) => !activePlayerIds.contains(p.id))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Active Players'),
              Tab(text: 'Bench'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Active Players Tab
                ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    if (activePlayers.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No active players. Add players to the lineup from the Bench tab.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ...currentLineup.entries.map((entry) {
                        final position = entry.key;
                        final playerId = entry.value;
                        final player = playersById[playerId];
                        if (player == null) return const SizedBox.shrink();

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$position: ${player.firstName} ${player.lastName}',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatPlayingTime(
                                    playingTimeThisGame[playerId] ?? 0,
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                            onTap: () => _showSubstitutionDialog(
                              context,
                              position,
                              player,
                            ),
                          ),
                        );
                      }),
                  ],
                ),

                // Bench Tab
                ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    if (benchPlayers.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'All players are active.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ...benchPlayers.map(
                        (player) => Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${player.firstName} ${player.lastName}',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatPlayingTime(
                                    playingTimeThisGame[player.id] ?? 0,
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                            onTap: () =>
                                _showPlayerReplacementDialog(context, player),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubstitutionDialog(
    BuildContext context,
    String position,
    Player currentPlayer,
  ) {
    // Get bench players for substitution
    final activePlayerIds = currentLineup.values.toSet();
    final availablePlayers = players
        .where((p) => !activePlayerIds.contains(p.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Substitute $position'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current: ${currentPlayer.firstName} ${currentPlayer.lastName}',
            ),
            const SizedBox(height: 16),
            const Text('Select replacement:'),
            const SizedBox(height: 8),
            ...availablePlayers.map(
              (player) => ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text('${player.firstName} ${player.lastName}'),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatPlayingTime(playingTimeThisGame[player.id] ?? 0),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onPlayerSubstitution(currentPlayer.id, player.id, position);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onPlayerSubstitution(currentPlayer.id, null, null);
            },
            child: const Text('Remove Only'),
          ),
        ],
      ),
    );
  }

  void _showPlayerReplacementDialog(BuildContext context, Player benchPlayer) {
    // Get active players for replacement
    final activeLineupEntries = currentLineup.entries.toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Substitute with ${benchPlayer.firstName} ${benchPlayer.lastName}',
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bench player: ${benchPlayer.firstName} ${benchPlayer.lastName}',
              ),
              const SizedBox(height: 16),
              const Text('Select player to replace:'),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: activeLineupEntries.map((entry) {
                    final position = entry.key;
                    final playerId = entry.value;
                    final activePlayer = players.firstWhere(
                      (p) => p.id == playerId,
                      orElse: () => Player(
                        id: playerId,
                        teamId: 0,
                        firstName: 'Unknown',
                        lastName: 'Player',
                        isPresent: false,
                      ),
                    );

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$position: ${activePlayer.firstName} ${activePlayer.lastName}',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.timer,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatPlayingTime(
                              playingTimeThisGame[playerId] ?? 0,
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        onPlayerSubstitution(
                          playerId,
                          benchPlayer.id,
                          position,
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _GameProgressTimeline extends StatelessWidget {
  final int currentHalf;
  final int gameTime;
  final int halfDurationSeconds;

  const _GameProgressTimeline({
    required this.currentHalf,
    required this.gameTime,
    required this.halfDurationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalGameSeconds = halfDurationSeconds * 2;

    // Calculate total elapsed time across both halves
    int totalElapsed;
    if (currentHalf == 1) {
      totalElapsed = gameTime;
    } else {
      // Second half: full first half + current time in second half
      totalElapsed = halfDurationSeconds + gameTime;
    }

    // Clamp to prevent overflow beyond 100%
    totalElapsed = totalElapsed.clamp(0, totalGameSeconds);

    final progress = totalElapsed / totalGameSeconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline labels
        Row(
          children: [
            Text(
              'Game Progress',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).round()}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress timeline
        SizedBox(
          height: 12,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final halfTimePosition = totalWidth * 0.5;

              return Stack(
                children: [
                  // Background track
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Actual progress bar based on total elapsed time
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // Half-time marker line
                  Positioned(
                    left: halfTimePosition - 1,
                    top: -2,
                    child: Container(
                      width: 2,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),

        // Timeline markers
        Row(
          children: [
            Text(
              '0\'',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              'HT',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${(halfDurationSeconds * 2 / 60).round()}\'',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _TraditionalGameMenuAction {
  edit,
  metricsView,
  metricsInput,
  attendance,
  reset,
}
