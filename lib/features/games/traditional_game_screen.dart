import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers.dart';
import '../../widgets/player_avatar.dart';
import '../../widgets/player_panel.dart';

class TraditionalGameScreen extends ConsumerStatefulWidget {
  final int gameId;
  const TraditionalGameScreen({super.key, required this.gameId});
  @override
  ConsumerState<TraditionalGameScreen> createState() =>
      _TraditionalGameScreenState();
}

class _TraditionalGameScreenState extends ConsumerState<TraditionalGameScreen>
    with WidgetsBindingObserver {
  late final ValueNotifier<int> _gameTimeNotifier;
  late final ValueNotifier<bool> _isRunningNotifier;
  late final ValueNotifier<int> _currentHalfNotifier;
  Timer? _gameTimer;
  int _halfDurationSeconds = 1200; // 20 minutes default

  // Current lineup tracking
  final Map<String, int> _currentLineup = {}; // position -> playerId
  final Map<int, int> _playingTimeThisGame = {}; // playerId -> seconds
  final Map<int, int> _lastSavedPlayingTime = {}; // playerId -> seconds

  // Formation positions - tracks all positions that should be available
  final List<String> _formationPositions = [];
  // Map full position names to abbreviations for display
  final Map<String, String> _positionAbbreviations = {};

  bool get _isRunning => _isRunningNotifier.value;
  set _isRunning(bool value) => _isRunningNotifier.value = value;

  int get _gameTime => _gameTimeNotifier.value;
  set _gameTime(int value) => _gameTimeNotifier.value = value;

  int get _currentHalf => _currentHalfNotifier.value;
  set _currentHalf(int value) => _currentHalfNotifier.value = value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gameTimeNotifier = ValueNotifier<int>(0);
    _isRunningNotifier = ValueNotifier<bool>(false);
    _currentHalfNotifier = ValueNotifier<int>(1);
    _loadGameState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App is going to background or being terminated
        if (_isRunning) {
          _saveCurrentState();
        }
        break;
      case AppLifecycleState.resumed:
        // App is coming back from background
        if (_isRunning) {
          _recalculateFromBackground();
        }
        break;
      case AppLifecycleState.inactive:
        // App is temporarily inactive (e.g., during phone calls)
        // Don't need to do anything special here
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still running
        break;
    }
  }

  Future<void> _saveCurrentState() async {
    final db = ref.read(dbProvider);
    // Save current game time and playing times
    await db.updateGameTime(widget.gameId, _gameTime);
    await _savePlayingTime();
  }

  Future<void> _recalculateFromBackground() async {
    final db = ref.read(dbProvider);
    final game = await db.getGame(widget.gameId);

    if (game != null && game.isGameActive && game.timerStartTime != null) {
      // Calculate how much time passed while in background
      final currentGameTime = await db.calculateCurrentGameTime(widget.gameId);
      final backgroundTime = currentGameTime - _gameTime;

      if (backgroundTime > 0) {
        // Update game time
        setState(() {
          _gameTime = currentGameTime;
        });

        // Add background time to current players' playing time
        for (final playerId in _currentLineup.values) {
          _playingTimeThisGame[playerId] =
              (_playingTimeThisGame[playerId] ?? 0) + backgroundTime;
        }

        // Update timer start time to now and save progress
        await db.updateGameTime(widget.gameId, currentGameTime);
        await db.updateTimerStartTime(widget.gameId);
        await _savePlayingTime();
      }
    }
  }

  Future<void> _loadFormationPositions(Game game) async {
    final db = ref.read(dbProvider);
    _formationPositions.clear();
    _positionAbbreviations.clear();

    // Get formation for this game
    int? formationId = game.formationId;
    formationId ??= await db.mostUsedFormationIdForTeam(game.teamId);

    if (formationId != null) {
      final positions = await db.getFormationPositions(formationId);
      for (final position in positions) {
        _formationPositions.add(position.positionName);
        _positionAbbreviations[position.positionName] = position.abbreviation;
      }
    }

    // Fallback to default positions if no formation found
    if (_formationPositions.isEmpty) {
      const defaultPositions = [
        'GOALIE',
        'RIGHT_DEFENSE',
        'LEFT_DEFENSE',
        'CENTER_FORWARD',
        'RIGHT_FORWARD',
        'LEFT_FORWARD',
      ];
      _formationPositions.addAll(defaultPositions);
      // Add default abbreviations for fallback positions
      _positionAbbreviations.addAll({
        'GOALIE': 'GK',
        'RIGHT_DEFENSE': 'RD',
        'LEFT_DEFENSE': 'LD',
        'CENTER_FORWARD': 'CF',
        'RIGHT_FORWARD': 'RF',
        'LEFT_FORWARD': 'LF',
      });
    }
  }

  /// Get position abbreviation for display, fallback to full name if not found
  String _getPositionAbbreviation(String positionName) {
    return _positionAbbreviations[positionName] ?? positionName;
  }

  String _getPlayerDisplayName(Player player) {
    final name = '${player.firstName} ${player.lastName}';
    if (player.jerseyNumber != null) {
      return '#${player.jerseyNumber} $name';
    }
    return name;
  }

  Future<void> _loadGameState() async {
    final db = ref.read(dbProvider);
    final game = await db.getGame(widget.gameId);

    if (game != null) {
      // Calculate actual current game time accounting for background time
      final currentGameTime = await db.calculateCurrentGameTime(widget.gameId);
      _gameTimeNotifier.value = currentGameTime;
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

      // Load formation positions for this game
      await _loadFormationPositions(game);

      // Load current game's lineup first, then auto-populate if still empty
      await _loadCurrentLineup();
      if (_currentLineup.isEmpty) {
        await _autoPopulateLineup(game.teamId);
      }

      // If timer was running when app was closed, calculate missed playing time
      if (game.isGameActive && game.timerStartTime != null) {
        final backgroundTime = currentGameTime - game.gameTimeSeconds;
        if (backgroundTime > 0) {
          // Add background time to players who were in the lineup
          for (final playerId in _currentLineup.values) {
            _playingTimeThisGame[playerId] =
                (_playingTimeThisGame[playerId] ?? 0) + backgroundTime;
          }
        }

        // Update timer start time to now and save current progress
        await db.updateGameTime(widget.gameId, currentGameTime);
        await db.updateTimerStartTime(widget.gameId);
        _startTimer();
      }
    }
  }

  Future<void> _loadCurrentLineup() async {
    final db = ref.read(dbProvider);

    // Try to load existing lineup for this game
    final existingLineup = await db.getTraditionalLineupFromGame(widget.gameId);

    if (existingLineup != null && existingLineup.isNotEmpty) {
      setState(() {
        _currentLineup.clear();
        _currentLineup.addAll(existingLineup);
        // Initialize last saved time to avoid double-counting
        for (final playerId in existingLineup.values) {
          _lastSavedPlayingTime[playerId] = _playingTimeThisGame[playerId] ?? 0;
        }
      });
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

        // Only use positions where players are still available AND positions match current formation
        final validLineup = <String, int>{};
        for (final entry in previousLineup.entries) {
          if (availablePlayerIds.contains(entry.value) &&
              _formationPositions.contains(entry.key)) {
            validLineup[entry.key] = entry.value;
          }
        }

        // Only use previous lineup if we have a reasonable number of matching positions
        // (at least half of the formation positions should be filled)
        if (validLineup.length >= (_formationPositions.length * 0.5).round()) {
          setState(() {
            _currentLineup.clear();
            _currentLineup.addAll(validLineup);
            // Initialize last saved time to avoid double-counting
            for (final playerId in validLineup.values) {
              _lastSavedPlayingTime[playerId] =
                  _playingTimeThisGame[playerId] ?? 0;
            }
          });
          // Save the lineup to database
          await db.saveTraditionalLineup(
            gameId: widget.gameId,
            lineup: _currentLineup,
          );
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
          // Save the generated lineup to database immediately
          await db.saveTraditionalLineup(
            gameId: widget.gameId,
            lineup: _currentLineup,
          );
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

      // Simple increment for normal operation
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

      // Save game time to database periodically (every 5 seconds to reduce DB calls)
      if (_gameTime % 5 == 0) {
        final db = ref.read(dbProvider);
        db.updateGameTime(widget.gameId, _gameTime);
      }
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
                case _TraditionalGameMenuAction.endGame:
                  if (!context.mounted) return;
                  context.push('/game/${widget.gameId}/end');
                  break;
                case _TraditionalGameMenuAction.home:
                  if (!context.mounted) return;
                  context.go('/');
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _TraditionalGameMenuAction.home,
                child: Text('Home'),
              ),
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
              PopupMenuItem(
                value: _TraditionalGameMenuAction.endGame,
                child: Text('End Game'),
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

              final allPlayers = playersSnap.data!;
              return StreamBuilder<List<GamePlayer>>(
                stream: db.watchAttendance(widget.gameId),
                builder: (context, attendanceSnap) {
                  if (attendanceSnap.connectionState ==
                          ConnectionState.waiting &&
                      !attendanceSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final attendance = attendanceSnap.data ?? <GamePlayer>[];

                  // Filter players to only include those present at this game
                  final players = <Player>[];
                  for (final player in allPlayers) {
                    // Find attendance record for this player
                    GamePlayer? attendanceRecord;
                    for (final record in attendance) {
                      if (record.playerId == player.id) {
                        attendanceRecord = record;
                        break;
                      }
                    }

                    // If no attendance record exists, fall back to player's default presence
                    // If attendance record exists, use its isPresent value
                    final isPresent =
                        attendanceRecord?.isPresent ?? player.isPresent;
                    if (isPresent) {
                      players.add(player);
                    }
                  }

                  final playersById = {for (final p in players) p.id: p};

                  return Column(
                    children: [
                      // Compact Game Control Section (only for in-progress games)
                      if (game.gameStatus == 'in-progress')
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: ValueListenableBuilder<int>(
                            valueListenable: _gameTimeNotifier,
                            builder: (context, gameTime, _) =>
                                ValueListenableBuilder<int>(
                                  valueListenable: _currentHalfNotifier,
                                  builder: (context, currentHalf, _) =>
                                      ValueListenableBuilder<bool>(
                                        valueListenable: _isRunningNotifier,
                                        builder: (context, isRunning, _) =>
                                            _CompactGameControl(
                                              currentHalf: currentHalf,
                                              gameTime: gameTime,
                                              halfDurationSeconds:
                                                  _halfDurationSeconds,
                                              isRunning: isRunning,
                                              onStartPause: () => isRunning
                                                  ? _pauseTimer()
                                                  : _startOrResumeTimer(),
                                              onSecondHalf: _currentHalf == 1
                                                  ? _startSecondHalf
                                                  : null,
                                            ),
                                      ),
                                ),
                          ),
                        )
                      else
                        // Show game completion status
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.flag,
                                      size: 32,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      game.gameStatus == 'completed'
                                          ? 'Game Completed'
                                          : 'Game ${game.gameStatus.toUpperCase()}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                    if (game.endTime != null)
                                      Text(
                                        'Ended: ${game.endTime!.toLocal().toString().split('.')[0]}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      const Divider(height: 1),

                      // Players Section
                      Expanded(
                        child: _TraditionalLineupView(
                          gameId: widget.gameId,
                          players: players,
                          playersById: playersById,
                          currentLineup: _currentLineup,
                          formationPositions: _formationPositions,
                          playingTimeThisGame: _playingTimeThisGame,
                          getPositionAbbreviation: _getPositionAbbreviation,
                          getPlayerDisplayName: _getPlayerDisplayName,
                          onPlayerSubstitution:
                              (outPlayerId, inPlayerId, position) async {
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

                                // Save lineup changes immediately
                                final db = ref.read(dbProvider);
                                await db.saveTraditionalLineup(
                                  gameId: widget.gameId,
                                  lineup: _currentLineup,
                                );
                              },
                        ),
                      ),
                    ],
                  );
                },
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
  final List<String> formationPositions;
  final Map<int, int> playingTimeThisGame;
  final Function(int? outPlayerId, int? inPlayerId, String? position)
  onPlayerSubstitution;
  final String Function(String) getPositionAbbreviation;
  final String Function(Player) getPlayerDisplayName;

  const _TraditionalLineupView({
    required this.gameId,
    required this.players,
    required this.playersById,
    required this.currentLineup,
    required this.formationPositions,
    required this.playingTimeThisGame,
    required this.onPlayerSubstitution,
    required this.getPositionAbbreviation,
    required this.getPlayerDisplayName,
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
                activePlayers.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No active players. Add players to the lineup from the Bench tab.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          // Header showing total active players
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                              child: Row(
                                children: [
                                  Text(
                                    'Lineup (${currentLineup.length}/${formationPositions.length})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.sports_soccer,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Players grid
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 3.5,
                                    crossAxisSpacing: 4,
                                    mainAxisSpacing: 4,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final position = formationPositions[index];
                                final playerId = currentLineup[position];
                                final player = playerId != null
                                    ? playersById[playerId]
                                    : null;

                                if (player != null) {
                                  // Position is filled
                                  return PlayerPanel(
                                    player: player,
                                    type: PlayerPanelType.active,
                                    position: position,
                                    playingTime:
                                        playingTimeThisGame[playerId] ?? 0,
                                    getPositionAbbreviation:
                                        getPositionAbbreviation,
                                    onTap: () => _showSubstitutionDialog(
                                      context,
                                      position,
                                      player,
                                    ),
                                  );
                                } else {
                                  // Empty position
                                  return Card(
                                    margin: EdgeInsets.zero,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerLowest,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => _showEmptyPositionDialog(
                                        context,
                                        position,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                // Position badge
                                                Flexible(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 4,
                                                          vertical: 1,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .outline
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            3,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      getPositionAbbreviation(
                                                        position,
                                                      ),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 10,
                                                          ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.add_circle_outline,
                                                  size: 16,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            // Empty state text
                                            Text(
                                              'Tap to assign',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              }, childCount: formationPositions.length),
                            ),
                          ),
                        ],
                      ),

                // Bench Tab
                benchPlayers.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'All players are active.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          // Header showing bench player count
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                              child: Row(
                                children: [
                                  Text(
                                    'Bench (${benchPlayers.length})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.event_seat,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Bench players grid
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 3.5,
                                    crossAxisSpacing: 4,
                                    mainAxisSpacing: 4,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final player = benchPlayers[index];
                                return PlayerPanel(
                                  player: player,
                                  type: PlayerPanelType.bench,
                                  playingTime:
                                      playingTimeThisGame[player.id] ?? 0,
                                  onTap: () => _showPlayerReplacementDialog(
                                    context,
                                    player,
                                  ),
                                );
                              }, childCount: benchPlayers.length),
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
        content: SizedBox(
          width: double.maxFinite,
          height: 400, // Set a maximum height for the dialog content
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current player display
                PlayerPanel(
                  player: currentPlayer,
                  type: PlayerPanelType.current,
                  position: position,
                  playingTime: playingTimeThisGame[currentPlayer.id] ?? 0,
                  getPositionAbbreviation: getPositionAbbreviation,
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select replacement:'),
                ),
                const SizedBox(height: 8),
                if (availablePlayers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'No players available on bench.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  // Available players grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(), // Let parent scroll
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3.2, // Increased for proper fit
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: availablePlayers.length,
                    itemBuilder: (context, index) {
                      final player = availablePlayers[index];
                      return PlayerPanel(
                        player: player,
                        type: PlayerPanelType.substitute,
                        playingTime: playingTimeThisGame[player.id] ?? 0,
                        onTap: () {
                          Navigator.of(context).pop();
                          onPlayerSubstitution(
                            currentPlayer.id,
                            player.id,
                            position,
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
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

  void _showEmptyPositionDialog(BuildContext context, String position) {
    // Get bench players for assignment
    final activePlayerIds = currentLineup.values.toSet();
    final availablePlayers = players
        .where((p) => !activePlayerIds.contains(p.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign player to ${getPositionAbbreviation(position)}'),
        content: SizedBox(
          width: double.maxFinite,
          height:
              MediaQuery.of(context).size.height *
              0.5, // Max 50% of screen height
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Empty position display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          getPositionAbbreviation(position),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Empty Position',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                      Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select player to assign:'),
                ),
                const SizedBox(height: 8),
                if (availablePlayers.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'No players available on bench.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  // Available players grid - using shrinkWrap instead of fixed height
                  GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(), // Let parent scroll
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio:
                              3.2, // Increased for more width and proper fit
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: availablePlayers.length,
                    itemBuilder: (context, index) {
                      final player = availablePlayers[index];
                      return PlayerPanel(
                        player: player,
                        type: PlayerPanelType.substitute,
                        playingTime: playingTimeThisGame[player.id] ?? 0,
                        onTap: () {
                          Navigator.of(context).pop();
                          onPlayerSubstitution(null, player.id, position);
                        },
                      );
                    },
                  ),
              ],
            ),
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

  void _showPlayerReplacementDialog(BuildContext context, Player benchPlayer) {
    // Get active players for replacement
    final activeLineupEntries = currentLineup.entries.toList();

    // Get open positions
    final openPositions = formationPositions
        .where((pos) => !currentLineup.containsKey(pos))
        .toList();

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
              // Bench player display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    PlayerAvatar(
                      firstName: benchPlayer.firstName,
                      lastName: benchPlayer.lastName,
                      jerseyNumber: benchPlayer.jerseyNumber,
                      profileImagePath: benchPlayer.profileImagePath,
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'SUB',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${benchPlayer.firstName} ${benchPlayer.lastName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatPlayingTime(
                        playingTimeThisGame[benchPlayer.id] ?? 0,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Available options - unified view
              const Text(
                'Choose a position:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: (activeLineupEntries.isEmpty && openPositions.isEmpty)
                    ? const Center(
                        child: Text(
                          'No positions available.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3.4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount:
                            activeLineupEntries.length + openPositions.length,
                        itemBuilder: (context, index) {
                          // First show occupied positions (for replacement)
                          if (index < activeLineupEntries.length) {
                            final entry = activeLineupEntries[index];
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

                            return Card(
                              margin: EdgeInsets.zero,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  onPlayerSubstitution(
                                    playerId,
                                    benchPlayer.id,
                                    position,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      // Player Avatar
                                      PlayerAvatar(
                                        firstName: activePlayer.firstName,
                                        lastName: activePlayer.lastName,
                                        jerseyNumber: activePlayer.jerseyNumber,
                                        profileImagePath:
                                            activePlayer.profileImagePath,
                                        radius: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      // Player and position info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  flex: 2,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 4,
                                                          vertical: 1,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            3,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      getPositionAbbreviation(
                                                        position,
                                                      ),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .onPrimaryContainer,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 9,
                                                          ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Icon(
                                                  Icons.timer,
                                                  size: 10,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 1),
                                                Text(
                                                  _formatPlayingTime(
                                                    playingTimeThisGame[playerId] ??
                                                        0,
                                                  ),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                        fontSize: 9,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              '${activePlayer.firstName} ${activePlayer.lastName}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 10,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          // Then show open positions (for assignment)
                          final openIndex = index - activeLineupEntries.length;
                          final position = openPositions[openIndex];

                          return Card(
                            margin: EdgeInsets.zero,
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLowest,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.of(context).pop();
                                onPlayerSubstitution(
                                  null,
                                  benchPlayer.id,
                                  position,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              getPositionAbbreviation(position),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 9,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.add_circle_outline,
                                          size: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 1),
                                    Flexible(
                                      child: Text(
                                        'Open Position',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontStyle: FontStyle.italic,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                              fontSize: 10,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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

class _CompactGameControl extends StatelessWidget {
  final int currentHalf;
  final int gameTime;
  final int halfDurationSeconds;
  final bool isRunning;
  final VoidCallback onStartPause;
  final VoidCallback? onSecondHalf;

  const _CompactGameControl({
    required this.currentHalf,
    required this.gameTime,
    required this.halfDurationSeconds,
    required this.isRunning,
    required this.onStartPause,
    this.onSecondHalf,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = halfDurationSeconds - gameTime;
    final over = remaining <= 0;
    final flashOn = over && (((-remaining) ~/ 2) % 2 == 0);

    // Calculate total game progress
    final totalGameSeconds = halfDurationSeconds * 2;
    int totalElapsed;
    if (currentHalf == 1) {
      totalElapsed = gameTime;
    } else {
      totalElapsed = halfDurationSeconds + gameTime;
    }
    totalElapsed = totalElapsed.clamp(0, totalGameSeconds);
    final progress = totalElapsed / totalGameSeconds;

    return Card(
      color: over && flashOn
          ? Colors.red.shade800
          : theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large time display at top
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  over ? '+${_formatTime(-remaining)}' : _formatTime(remaining),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Timeline with embedded half labels
            Column(
              children: [
                // Half labels above timeline
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '1st Half',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: currentHalf == 1
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: currentHalf == 1
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '2nd Half',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: currentHalf == 2
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: currentHalf == 2
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Timeline progress bar
                Row(
                  children: [
                    Text(
                      '0\'',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 8,
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
                                    color: theme.colorScheme.outline.withValues(
                                      alpha: 0.3,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),

                                // Progress bar
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

                                // Half-time marker
                                Positioned(
                                  left: halfTimePosition - 1,
                                  top: 0,
                                  child: Container(
                                    width: 2,
                                    height: 8,
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
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(halfDurationSeconds * 2 / 60).round()}\'',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Controls row
            Row(
              children: [
                // Left side - Start/Pause button under current half
                Expanded(
                  child: currentHalf == 1
                      ? FilledButton.icon(
                          icon: Icon(
                            isRunning ? Icons.pause : Icons.play_arrow,
                            size: 16,
                          ),
                          label: Text(isRunning ? 'Pause' : 'Start'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: onStartPause,
                        )
                      : const SizedBox.shrink(),
                ),

                // Center - Empty space (time is now at top)
                const Expanded(child: SizedBox.shrink()),

                // Right side - 2nd Half button (first half) or Start/Pause (second half)
                Expanded(
                  child: currentHalf == 1
                      ? (onSecondHalf != null
                            ? Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.skip_next, size: 16),
                                  label: const Text('2nd Half'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: onSecondHalf,
                                ),
                              )
                            : const SizedBox.shrink())
                      : FilledButton.icon(
                          icon: Icon(
                            isRunning ? Icons.pause : Icons.play_arrow,
                            size: 16,
                          ),
                          label: Text(isRunning ? 'Pause' : 'Start'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: onStartPause,
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

enum _TraditionalGameMenuAction {
  edit,
  metricsView,
  metricsInput,
  attendance,
  reset,
  endGame,
  home,
}
