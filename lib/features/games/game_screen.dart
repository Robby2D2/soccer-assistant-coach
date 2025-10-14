import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers.dart';
import '../../core/positions.dart';
import '../../data/services/stopwatch_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/alert_service.dart';
import '../../widgets/player_panel.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int gameId;
  const GameScreen({super.key, required this.gameId});
  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final ValueNotifier<int> _secondsNotifier;
  late final ProviderSubscription<int> _stopwatchSubscription;
  late final ValueNotifier<bool> _isRunningNotifier;
  bool get _isRunning => _isRunningNotifier.value;
  set _isRunning(bool value) => _isRunningNotifier.value = value;
  int _lastTickSeconds = 0;
  int? _currentShiftId;
  int _currentShiftStartSeconds = 0;
  bool _initialShiftCreated = false;
  bool _creatingInitialShift = false;
  int _shiftLengthSeconds = 300;
  int? _shiftLenForTeamId;
  bool _alertedThisShift = false;
  late final ValueNotifier<bool> _alertActiveNotifier;
  final GlobalKey<_ShiftsListState> _shiftsListKey =
      GlobalKey<_ShiftsListState>();

  // Formation position abbreviations mapping
  final Map<String, String> _positionAbbreviations = <String, String>{};
  bool _formationDataLoaded = false;

  // Compute shift number helper to avoid duplicating query/sort logic
  Future<int?> _shiftNumberFor(AppDb db, int shiftId) async {
    try {
      final shifts = await db.watchGameShifts(widget.gameId).first;
      if (shifts.isEmpty) return null;
      final sorted = [...shifts]
        ..sort((a, b) => a.startSeconds.compareTo(b.startSeconds));
      for (var i = 0; i < sorted.length; i++) {
        if (sorted[i].id == shiftId) return i + 1;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _secondsNotifier = ValueNotifier<int>(
      ref.read(stopwatchProvider(widget.gameId)),
    );
    _isRunningNotifier = ValueNotifier<bool>(false);
    _alertActiveNotifier = ValueNotifier<bool>(false);
    _lastTickSeconds = _secondsNotifier.value;
    _checkInitialRunningState();
    _loadFormationPositions(); // Load formation abbreviations

    // Check if this is a new game with no shifts and reset stopwatch if needed
    _checkAndResetForNewGame();
    _stopwatchSubscription = ref.listenManual<int>(
      stopwatchProvider(widget.gameId),
      (previous, next) {
        if (!mounted || next == previous) return;
        final database = ref.read(dbProvider);
        _handleTick(database, next);
        _secondsNotifier.value = next;
        _lastTickSeconds = next;
      },
      fireImmediately: false,
    );
  }

  Future<void> _checkInitialRunningState() async {
    final prefs = await SharedPreferences.getInstance();
    final startedAtKey = 'timer_started_at_${widget.gameId}';
    final isRunning = prefs.getInt(startedAtKey) != null;
    _isRunning = isRunning;
  }

  Future<void> _checkAndResetForNewGame() async {
    final db = ref.read(dbProvider);
    final shifts = await db.watchGameShifts(widget.gameId).first;

    // If the game has no shifts yet, reset the stopwatch to start fresh
    if (shifts.isEmpty && !_isRunning) {
      final stopwatchCtrl = ref.read(stopwatchProvider(widget.gameId).notifier);
      await stopwatchCtrl.reset();

      // Update the seconds notifier to 0
      if (mounted) {
        _secondsNotifier.value = 0;
        _lastTickSeconds = 0;
      }
    }
  }

  Future<void> _loadFormationPositions() async {
    if (_formationDataLoaded) return;

    final db = ref.read(dbProvider);
    _positionAbbreviations.clear();

    try {
      // Get the game to find its formation
      final game = await db.getGame(widget.gameId);
      if (game == null) return;

      // Get formation for this game
      int? formationId = game.formationId;
      formationId ??= await db.mostUsedFormationIdForTeam(game.teamId);

      if (formationId != null) {
        final positions = await db.getFormationPositions(formationId);
        for (final position in positions) {
          _positionAbbreviations[position.positionName] = position.abbreviation;
        }
      }

      // Fallback to default abbreviations if no formation found
      if (_positionAbbreviations.isEmpty) {
        _positionAbbreviations.addAll({
          'GOALIE': 'GK',
          'RIGHT_DEFENSE': 'RD',
          'LEFT_DEFENSE': 'LD',
          'CENTER_FORWARD': 'CF',
          'RIGHT_FORWARD': 'RF',
          'LEFT_FORWARD': 'LF',
        });
      }

      _formationDataLoaded = true;
    } catch (e) {
      // Fallback to default abbreviations on error
      _positionAbbreviations.addAll({
        'GOALIE': 'GK',
        'RIGHT_DEFENSE': 'RD',
        'LEFT_DEFENSE': 'LD',
        'CENTER_FORWARD': 'CF',
        'RIGHT_FORWARD': 'RF',
        'LEFT_FORWARD': 'LF',
      });
      _formationDataLoaded = true;
    }
  }

  /// Get position abbreviation for display, fallback to full name if not found
  String _getPositionAbbreviation(String positionName) {
    return _positionAbbreviations[positionName] ?? positionName;
  }

  @override
  void dispose() {
    _stopwatchSubscription.close();
    _secondsNotifier.dispose();
    _isRunningNotifier.dispose();
    _alertActiveNotifier.dispose();
    // Clean up shift countdown notifications when leaving the game screen
    NotificationService.instance.cancelShiftCountdown(widget.gameId);
    super.dispose();
  }

  Future<List<String>> _positionsFromShiftId(AppDb db, int shiftId) async {
    final assignments = await db.getAssignments(shiftId);
    if (assignments.isEmpty) return kPositions;
    final firstIdPerPosition = <String, int>{};
    for (final a in assignments) {
      final prev = firstIdPerPosition[a.position];
      if (prev == null || a.id < prev) {
        firstIdPerPosition[a.position] = a.id;
      }
    }
    final entries = firstIdPerPosition.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return [for (final e in entries) e.key];
  }

  Future<List<String>> _positionsForNextShift(AppDb db) async {
    final shifts = await db.watchGameShifts(widget.gameId).first;
    if (shifts.isEmpty) return kPositions;

    // Look for formation template shifts (far future shifts used as templates)
    final formationTemplates = shifts.where((s) => s.startSeconds > 9000);
    if (formationTemplates.isNotEmpty) {
      // Use the most recent formation template
      final latest = formationTemplates.reduce(
        (a, b) => a.startSeconds > b.startSeconds ? a : b,
      );
      return _positionsFromShiftId(db, latest.id);
    }

    // Sort shifts chronologically
    final chronological = [...shifts]
      ..sort((a, b) => a.startSeconds.compareTo(b.startSeconds));

    // Prefer using positions from the current (or last) shift.
    if (_currentShiftId != null) {
      return _positionsFromShiftId(db, _currentShiftId!);
    }
    if (chronological.isNotEmpty) {
      return _positionsFromShiftId(db, chronological.last.id);
    }
    return kPositions;
  }

  void _startAlertStatusMonitoring() {
    // Check alert status every second to update the UI
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final isAlerting = AlertService.instance.isAlerting;
      if (_alertActiveNotifier.value != isAlerting) {
        _alertActiveNotifier.value = isAlerting;
      }

      // Cancel timer if alert is no longer active
      if (!isAlerting) {
        timer.cancel();
      }
    });
  }

  void _acknowledgeAlert() {
    AlertService.instance.acknowledgeAlert();
    _alertActiveNotifier.value = false;
  }

  Future<void> _handleTick(AppDb db, int seconds) async {
    if (_isRunning && _currentShiftId != null) {
      final delta = seconds - _lastTickSeconds;
      if (delta > 0) {
        await db.incrementShiftDuration(_currentShiftId!, delta);
      }

      // Update shift countdown notification
      final game = await db.getGame(widget.gameId);
      if (game != null) {
        final team = await db.getTeam(game.teamId);
        final teamName = team?.name ?? 'Team';
        final opponent = game.opponent ?? '';
        final matchupTitle = opponent.isEmpty
            ? teamName
            : '$teamName vs $opponent';
        final shiftNumber = await _shiftNumberFor(db, _currentShiftId!);

        await NotificationService.instance.showOrUpdateShiftCountdown(
          gameId: widget.gameId,
          currentSeconds: seconds,
          shiftLengthSeconds: _shiftLengthSeconds,
          matchupTitle: matchupTitle,
          shiftNumber: shiftNumber,
        );
      }

      // Alert once when countdown reaches zero
      if (!_alertedThisShift && seconds >= _shiftLengthSeconds) {
        _alertedThisShift = true;
        // Trigger enhanced shift change alert with audio and strong haptic feedback
        AlertService.instance.triggerShiftChangeAlert(
          gameId: widget.gameId,
          durationSeconds: 60,
        );
        _alertActiveNotifier.value = true;

        // Start monitoring alert status
        _startAlertStatusMonitoring();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Shift time! Tap to acknowledge alert.'),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {
                  _acknowledgeAlert();
                },
              ),
              duration: const Duration(seconds: 10),
            ),
          );
        }
      }
    }
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
            if (game != null && _shiftLenForTeamId != game.teamId) {
              // Lazy-load per-team shift length
              _shiftLenForTeamId = game.teamId;
              db.getTeamShiftLengthSeconds(game.teamId).then((value) {
                if (!mounted) return;
                setState(() => _shiftLengthSeconds = value);
              });
            }
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
          FutureBuilder<Game?>(
            future: db.getGame(widget.gameId),
            builder: (context, snap) {
              final game = snap.data;
              final isGameEnded =
                  game?.gameStatus == 'completed' ||
                  game?.gameStatus == 'cancelled';

              return PopupMenuButton<_GameMenuAction>(
                onSelected: (value) async {
                  switch (value) {
                    case _GameMenuAction.home:
                      if (!context.mounted) return;
                      context.go('/');
                      break;
                    case _GameMenuAction.edit:
                      if (!context.mounted) return;
                      context.push('/game/${widget.gameId}/edit');
                      break;
                    case _GameMenuAction.lineup:
                      if (!context.mounted) return;
                      context.push('/game/${widget.gameId}/formation');
                      break;
                    case _GameMenuAction.metricsView:
                      if (!context.mounted) return;
                      context.push('/game/${widget.gameId}/metrics');
                      break;
                    case _GameMenuAction.metricsInput:
                      if (!context.mounted) return;
                      context.push('/game/${widget.gameId}/metrics/input');
                      break;
                    case _GameMenuAction.attendance:
                      if (!context.mounted) return;
                      context.push('/game/${widget.gameId}/attendance');
                      break;
                    case _GameMenuAction.reset:
                      // Update local state with setState to ensure UI updates for reset
                      setState(() {
                        _isRunning = false;
                        _currentShiftId = null;
                        _lastTickSeconds = 0;
                        _currentShiftStartSeconds = 0;
                      });
                      final sw = ref.read(
                        stopwatchProvider(widget.gameId).notifier,
                      );
                      await sw.reset();
                      await NotificationService.instance.cancelStopwatch(
                        widget.gameId,
                      );
                      await NotificationService.instance.cancelShiftEnd(
                        widget.gameId,
                      );
                      await NotificationService.instance.cancelShiftCountdown(
                        widget.gameId,
                      );
                      break;
                    case _GameMenuAction.endGame:
                      if (!context.mounted) return;
                      context.push('/game/${widget.gameId}/end');
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _GameMenuAction.home,
                    child: Text('Home'),
                  ),
                  const PopupMenuItem(
                    value: _GameMenuAction.edit,
                    child: Text('Edit game'),
                  ),
                  const PopupMenuItem(
                    value: _GameMenuAction.lineup,
                    child: Text('Formation'),
                  ),
                  const PopupMenuItem(
                    value: _GameMenuAction.metricsView,
                    child: Text('View Metrics'),
                  ),
                  const PopupMenuItem(
                    value: _GameMenuAction.metricsInput,
                    child: Text('Input Metrics'),
                  ),
                  const PopupMenuItem(
                    value: _GameMenuAction.attendance,
                    child: Text('Attendance'),
                  ),
                  const PopupMenuItem(
                    value: _GameMenuAction.reset,
                    child: Text('Reset stopwatch'),
                  ),
                  // Only show "End Game" if the game is not already ended
                  if (!isGameEnded)
                    const PopupMenuItem(
                      value: _GameMenuAction.endGame,
                      child: Text('End Game'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<Game?>(
              future: db.getGame(widget.gameId),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final game = snap.data;
                if (game == null) {
                  return const Center(child: Text('Game not found'));
                }

                return StreamBuilder<List<Player>>(
                  stream: db.watchPlayersByTeam(game.teamId),
                  builder: (context, playersSnap) {
                    if (playersSnap.connectionState ==
                            ConnectionState.waiting &&
                        !playersSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final players = playersSnap.data ?? const <Player>[];
                    final playersById = {for (final p in players) p.id: p};
                    _currentShiftId ??= game.currentShiftId;

                    return StreamBuilder<List<Shift>>(
                      stream: db.watchGameShifts(widget.gameId),
                      builder: (context, shiftsSnap) {
                        final isLoading =
                            shiftsSnap.connectionState ==
                                ConnectionState.waiting &&
                            !shiftsSnap.hasData;
                        final chronological =
                            [...(shiftsSnap.data ?? const <Shift>[])]..sort(
                              (a, b) =>
                                  a.startSeconds.compareTo(b.startSeconds),
                            );
                        if (chronological.isNotEmpty) {
                          _initialShiftCreated = true;
                        }
                        final shiftNumbers = <int, int>{
                          for (var i = 0; i < chronological.length; i++)
                            chronological[i].id: i + 1,
                        };
                        Shift? currentShift;
                        if (game.currentShiftId != null) {
                          for (final s in chronological) {
                            if (s.id == game.currentShiftId) {
                              currentShift = s;
                              break;
                            }
                          }
                        }

                        if (currentShift != null) {
                          _currentShiftStartSeconds = currentShift.startSeconds;
                        }

                        if (!isLoading &&
                            chronological.isEmpty &&
                            !_initialShiftCreated &&
                            !_creatingInitialShift) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _ensureInitialShift(db, game);
                          });
                        }

                        Shift? upcomingShift;
                        if (currentShift != null) {
                          final current = currentShift;
                          final later = chronological.where(
                            (s) => s.startSeconds > current.startSeconds,
                          );
                          upcomingShift = later.isEmpty ? null : later.first;
                        } else if (chronological.isNotEmpty) {
                          upcomingShift = chronological.first;
                        }

                        final nextShiftId = upcomingShift?.id;

                        // theme reference removed (unused)

                        final columnChildren = <Widget>[
                          // Current shift title with optional next shift link
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      final currentShiftId =
                                          _currentShiftId ??
                                          game.currentShiftId;
                                      if (currentShiftId != null) {
                                        _shiftsListKey.currentState
                                            ?.scrollToShift(currentShiftId);
                                      }
                                    },
                                    child: Text(
                                      () {
                                        final id =
                                            _currentShiftId ??
                                            game.currentShiftId;
                                        if (id == null) {
                                          return 'No Current Shift';
                                        }
                                        final order = shiftNumbers[id];
                                        return order == null
                                            ? 'Current Shift'
                                            : 'Shift #$order';
                                      }(),
                                      textAlign: TextAlign.left,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                ),
                                if (nextShiftId != null)
                                  GestureDetector(
                                    onTap: () {
                                      _shiftsListKey.currentState
                                          ?.scrollToShift(nextShiftId);
                                    },
                                    child: Text(
                                      'See next shift',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Stopwatch card (only show for in-progress games)
                          if (game.gameStatus == 'in-progress') ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: ValueListenableBuilder<int>(
                                valueListenable: _secondsNotifier,
                                builder: (context, seconds, _) {
                                  // For shift-based timing, use the shift's actual seconds
                                  // instead of the stopwatch elapsed time to avoid issues
                                  // with stale stopwatch state
                                  final shiftSeconds = _currentShiftId != null
                                      ? seconds
                                      : 0;
                                  final remaining =
                                      _shiftLengthSeconds - shiftSeconds;
                                  final over = remaining <= 0;
                                  final flashOn =
                                      over && ((-remaining) % 2 == 0);
                                  final theme = Theme.of(context);
                                  final baseline =
                                      theme.colorScheme.surfaceContainerHighest;
                                  final panelColor = over
                                      ? (flashOn
                                            ? Colors.red.shade800
                                            : baseline)
                                      : baseline;
                                  return Card(
                                    color: panelColor,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: Text(
                                            _hhmmssSigned(remaining),
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
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: ValueListenableBuilder<bool>(
                                valueListenable: _isRunningNotifier,
                                builder: (context, isRunning, _) => Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (!isRunning)
                                      FutureBuilder<Game?>(
                                        future: db.getGame(widget.gameId),
                                        builder: (context, gameSnap) {
                                          final game = gameSnap.data;
                                          final hasCurrentShift =
                                              game?.currentShiftId != null;
                                          final buttonText = hasCurrentShift
                                              ? 'Resume'
                                              : 'Start';
                                          final tooltipText = hasCurrentShift
                                              ? 'Resume current shift timer'
                                              : 'Start timer';

                                          return Tooltip(
                                            message: tooltipText,
                                            child: FilledButton.icon(
                                              icon: const Icon(
                                                Icons.play_arrow_rounded,
                                              ),
                                              label: Text(buttonText),
                                              onPressed: () async {
                                                final stopwatchCtrl = ref.read(
                                                  stopwatchProvider(
                                                    widget.gameId,
                                                  ).notifier,
                                                );
                                                final game = await db.getGame(
                                                  widget.gameId,
                                                );
                                                final int shiftId;
                                                final currentId =
                                                    game?.currentShiftId;
                                                final bool isNewShift =
                                                    currentId == null;

                                                if (currentId != null) {
                                                  shiftId = currentId;
                                                } else {
                                                  final positions =
                                                      await _positionsForNextShift(
                                                        db,
                                                      );
                                                  shiftId = await db
                                                      .createAutoShift(
                                                        gameId: widget.gameId,
                                                        startSeconds:
                                                            _currentShiftStartSeconds,
                                                        positions: positions,
                                                      );
                                                }

                                                final shift = await db.getShift(
                                                  shiftId,
                                                );
                                                if (shift != null) {
                                                  _currentShiftStartSeconds =
                                                      shift.startSeconds;
                                                }

                                                // Pre-create the upcoming shift
                                                final upcomingStart =
                                                    _currentShiftStartSeconds +
                                                    _shiftLengthSeconds;
                                                final hasPrepared =
                                                    await db.nextShiftAfter(
                                                      widget.gameId,
                                                      _currentShiftStartSeconds,
                                                    ) !=
                                                    null;
                                                if (!hasPrepared) {
                                                  final nextPositions =
                                                      await _positionsForNextShift(
                                                        db,
                                                      );
                                                  await db.createAutoShift(
                                                    gameId: widget.gameId,
                                                    startSeconds: upcomingStart,
                                                    positions: nextPositions,
                                                    activate: false,
                                                  );
                                                }
                                                // Set metadata for notification (team vs opponent, shift length)
                                                final gameForMeta = await db
                                                    .getGame(widget.gameId);
                                                if (gameForMeta != null) {
                                                  final team = await db.getTeam(
                                                    gameForMeta.teamId,
                                                  );
                                                  final teamName =
                                                      team?.name ?? 'Team';
                                                  final opponent =
                                                      gameForMeta.opponent ??
                                                      '';
                                                  final shiftNumber =
                                                      await _shiftNumberFor(
                                                        db,
                                                        shiftId,
                                                      );
                                                  await stopwatchCtrl.setMeta(
                                                    teamName: teamName,
                                                    opponent: opponent,
                                                    shiftLengthSeconds:
                                                        _shiftLengthSeconds,
                                                    shiftNumber: shiftNumber,
                                                  );
                                                }

                                                // Get the shift's current time
                                                final shiftData = await db
                                                    .getShift(shiftId);
                                                final startFromSeconds =
                                                    shiftData?.actualSeconds ??
                                                    0;

                                                // Only reset stopwatch for new shifts, not when resuming
                                                if (isNewShift) {
                                                  await stopwatchCtrl.reset();

                                                  // Set the stopwatch state to match the shift's current time
                                                  // This ensures the timer starts from the correct position
                                                  if (startFromSeconds > 0) {
                                                    // Manually set the state to the shift's current time
                                                    final prefs =
                                                        await SharedPreferences.getInstance();
                                                    await prefs.setInt(
                                                      'timer_elapsed_${widget.gameId}',
                                                      startFromSeconds,
                                                    );
                                                    // Update the notifier to reflect the correct starting time
                                                    _secondsNotifier.value =
                                                        startFromSeconds;
                                                    _lastTickSeconds =
                                                        startFromSeconds;
                                                  }
                                                }

                                                await stopwatchCtrl.start();
                                                if (!context.mounted) return;
                                                // Update local state - StreamBuilder will handle most updates
                                                _currentShiftId = shiftId;
                                                _isRunning = true;
                                                _lastTickSeconds =
                                                    startFromSeconds;
                                                _alertedThisShift =
                                                    startFromSeconds >=
                                                    _shiftLengthSeconds;

                                                // Start shift countdown notification
                                                final gameForNotif = await db
                                                    .getGame(widget.gameId);
                                                if (gameForNotif != null) {
                                                  final team = await db.getTeam(
                                                    gameForNotif.teamId,
                                                  );
                                                  final teamName =
                                                      team?.name ?? 'Team';
                                                  final opponent =
                                                      gameForNotif.opponent ??
                                                      '';
                                                  final matchupTitle =
                                                      opponent.isEmpty
                                                      ? teamName
                                                      : '$teamName vs $opponent';
                                                  final shiftNumber =
                                                      await _shiftNumberFor(
                                                        db,
                                                        shiftId,
                                                      );

                                                  await NotificationService
                                                      .instance
                                                      .startShiftCountdown(
                                                        gameId: widget.gameId,
                                                        shiftLengthSeconds:
                                                            _shiftLengthSeconds,
                                                        matchupTitle:
                                                            matchupTitle,
                                                        shiftNumber:
                                                            shiftNumber,
                                                      );
                                                }
                                                final remaining =
                                                    _shiftLengthSeconds -
                                                    _secondsNotifier.value;
                                                if (remaining > 0) {
                                                  final when = DateTime.now()
                                                      .add(
                                                        Duration(
                                                          seconds: remaining,
                                                        ),
                                                      );
                                                  await NotificationService
                                                      .instance
                                                      .cancelShiftEnd(
                                                        widget.gameId,
                                                      );
                                                  try {
                                                    await NotificationService
                                                        .instance
                                                        .scheduleShiftEnd(
                                                          gameId: widget.gameId,
                                                          at: when,
                                                        );
                                                  } catch (e) {
                                                    // Show user-friendly message if notification scheduling fails
                                                    if (mounted &&
                                                        e.toString().contains(
                                                          'exact_alarms_not_permitted',
                                                        )) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Shift notifications may be less accurate. Enable exact alarms in Android settings for better timing.',
                                                            ),
                                                            duration: Duration(
                                                              seconds: 4,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  }
                                                } else {
                                                  // No future shift-end notification if already at/over time
                                                  await NotificationService
                                                      .instance
                                                      .cancelShiftEnd(
                                                        widget.gameId,
                                                      );
                                                }
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    // "Start next shift" button - only show when timer is not running and there's a next shift
                                    if (!isRunning && nextShiftId != null)
                                      Tooltip(
                                        message: 'Start next shift immediately',
                                        child: FilledButton.icon(
                                          icon: const Icon(Icons.skip_next),
                                          label: const Text('Start next'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                            foregroundColor: Theme.of(
                                              context,
                                            ).colorScheme.onSecondary,
                                          ),
                                          onPressed: () async {
                                            await _handleStartNextShift(
                                              context,
                                              db,
                                              nextShiftId,
                                            );
                                          },
                                        ),
                                      ),
                                    if (isRunning)
                                      Tooltip(
                                        message: 'Pause timer',
                                        child: FilledButton.icon(
                                          icon: const Icon(Icons.pause_rounded),
                                          label: const Text('Pause'),
                                          onPressed: () async {
                                            await ref
                                                .read(
                                                  stopwatchProvider(
                                                    widget.gameId,
                                                  ).notifier,
                                                )
                                                .pause();
                                            await NotificationService.instance
                                                .cancelShiftEnd(widget.gameId);
                                            await NotificationService.instance
                                                .cancelShiftCountdown(
                                                  widget.gameId,
                                                );
                                            // Update running state without setState to avoid scroll jump
                                            _isRunning = false;
                                          },
                                        ),
                                      ),
                                    // Reset moved to kebab menu
                                  ],
                                ),
                              ),
                            ),
                            // Stop Alert button - show when alert is active
                            ValueListenableBuilder<bool>(
                              valueListenable: _alertActiveNotifier,
                              builder: (context, isAlerting, child) {
                                if (!isAlerting) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Center(
                                    child: FilledButton.icon(
                                      onPressed: _acknowledgeAlert,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        foregroundColor: Theme.of(
                                          context,
                                        ).colorScheme.onError,
                                      ),
                                      icon: const Icon(Icons.alarm_off),
                                      label: const Text('Stop Alert'),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ] else ...[
                            // Show completion status for finished games
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: Card(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.flag,
                                          size: 48,
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
                                              .headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                        ),
                                        if (game.endTime != null)
                                          Text(
                                            'Ended: ${_formatDateTime(game.endTime!)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          // Removed separate "Time left" row; big timer is countdown
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Divider(height: 1),
                          ),
                          const SizedBox(height: 8),
                        ];

                        if (isLoading) {
                          columnChildren.add(
                            const Expanded(
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        } else if (chronological.isEmpty) {
                          columnChildren.add(
                            const Expanded(
                              child: Center(
                                child: Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('No shifts recorded yet.'),
                                  ),
                                ),
                              ),
                            ),
                          );
                        } else {
                          // Buttons to prepare/regenerate next shift removed

                          // (Play Time chart moved to Metrics screen)

                          columnChildren.add(
                            Expanded(
                              child: _ShiftsList(
                                key: _shiftsListKey,
                                shifts: chronological,
                                shiftNumbers: shiftNumbers,
                                currentShiftId:
                                    _currentShiftId ?? game.currentShiftId,
                                nextShiftId: nextShiftId,
                                playersById: playersById,
                                db: db,
                                onRemovePlayer: (shift, assignment) =>
                                    _handleRemovePlayerFromShift(
                                      context,
                                      db,
                                      shift,
                                      assignment,
                                    ),
                                getPositionAbbreviation:
                                    _getPositionAbbreviation,
                              ),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: columnChildren,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _ensureInitialShift(AppDb db, Game game) async {
    if (_initialShiftCreated || _creatingInitialShift) return;
    _creatingInitialShift = true;
    try {
      final hasPresent = await db.hasPresentPlayersForGame(game.id);
      if (!hasPresent) {
        _creatingInitialShift = false;
        return;
      }

      // Reset the stopwatch for a fresh start when creating the initial shift
      final stopwatchCtrl = ref.read(stopwatchProvider(widget.gameId).notifier);
      await stopwatchCtrl.reset();

      // Update the seconds notifier to 0 to reflect the reset
      _secondsNotifier.value = 0;
      _lastTickSeconds = 0;

      // Fallback to default positions only when no initial formation was applied.
      final newShiftId = await db.createAutoShift(
        gameId: widget.gameId,
        startSeconds: 0,
        positions: kPositions,
      );
      if (!mounted) {
        _creatingInitialShift = false;
        return;
      }
      // Update local state without setState to avoid scroll jump
      _initialShiftCreated = true;
      _currentShiftId = newShiftId;
      _currentShiftStartSeconds = 0;
    } finally {
      _creatingInitialShift = false;
    }
  }

  Future<void> _handleRemovePlayerFromShift(
    BuildContext context,
    AppDb db,
    Shift shift,
    PlayerShift assignment,
  ) async {
    final player = await db.getPlayer(assignment.playerId);
    final name = player == null
        ? 'Player #${assignment.playerId}'
        : '${player.firstName} ${player.lastName}';
    if (!context.mounted) return;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove from shift'),
            content: Text(
              'Remove $name from ${assignment.position}? The spot will be filled automatically.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
    if (!context.mounted) return;
    if (!confirmed) return;
    await db.removePlayerFromShift(
      shiftId: shift.id,
      playerId: assignment.playerId,
      position: assignment.position,
      gameId: shift.gameId,
      startSeconds: shift.startSeconds,
    );
    if (!context.mounted) return;
    // No setState needed - StreamBuilder will update automatically
  }

  Future<void> _handleStartNextShift(
    BuildContext context,
    AppDb db,
    int nextShiftId,
  ) async {
    // Check if there's time remaining in current shift
    final currentSeconds = _secondsNotifier.value;
    final timeRemaining = _shiftLengthSeconds - currentSeconds;

    if (timeRemaining > 0) {
      // Show confirmation dialog if there's time left in current shift
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start next shift early?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'There are still ${_formatTimeRemaining(timeRemaining)} remaining in the current shift.',
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to start the next shift now?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Start Next Shift'),
            ),
          ],
        ),
      );

      if (confirmed != true) return; // User cancelled or dialog dismissed
    }

    await _startNextShift(db, nextShiftId);
  }

  Future<void> _startNextShift(AppDb db, int nextShiftId) async {
    // First, pause the current timer if running
    if (_isRunning) {
      await ref.read(stopwatchProvider(widget.gameId).notifier).pause();
      await NotificationService.instance.cancelShiftEnd(widget.gameId);
      await NotificationService.instance.cancelShiftCountdown(widget.gameId);
      _isRunning = false;
    }

    // Get the next shift
    final nextShift = await db.getShift(nextShiftId);
    if (nextShift == null) return;

    // Make the next shift current
    await (db.update(db.games)..where((g) => g.id.equals(nextShift.gameId)))
        .write(GamesCompanion(currentShiftId: drift.Value(nextShift.id)));

    // Update local state
    setState(() {
      _currentShiftId = nextShift.id;
      _currentShiftStartSeconds = nextShift.startSeconds;
      _lastTickSeconds = nextShift.actualSeconds;
      _alertedThisShift = nextShift.actualSeconds >= _shiftLengthSeconds;
    });

    // Reset the stopwatch and set it to the shift's current time
    final stopwatchCtrl = ref.read(stopwatchProvider(widget.gameId).notifier);
    await stopwatchCtrl.reset();

    if (nextShift.actualSeconds > 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'timer_elapsed_${widget.gameId}',
        nextShift.actualSeconds,
      );
    }

    _secondsNotifier.value = nextShift.actualSeconds;

    // Set metadata for notification
    final game = await db.getGame(widget.gameId);
    if (game != null) {
      final team = await db.getTeam(game.teamId);
      final teamName = team?.name ?? 'Team';
      final opponent = game.opponent ?? '';
      final shiftNumber = await _shiftNumberFor(db, nextShift.id);
      await stopwatchCtrl.setMeta(
        teamName: teamName,
        opponent: opponent,
        shiftLengthSeconds: _shiftLengthSeconds,
        shiftNumber: shiftNumber,
      );
    }

    // Start the timer
    await stopwatchCtrl.start();

    // Update running state
    _isRunning = true;
    _lastTickSeconds = nextShift.actualSeconds;

    // Start shift countdown notification
    final gameForNotif = await db.getGame(widget.gameId);
    if (gameForNotif != null) {
      final team = await db.getTeam(gameForNotif.teamId);
      final teamName = team?.name ?? 'Team';
      final opponent = gameForNotif.opponent ?? '';
      final matchupTitle = opponent.isEmpty
          ? teamName
          : '$teamName vs $opponent';
      final shiftNumber = await _shiftNumberFor(db, nextShift.id);

      await NotificationService.instance.showOrUpdateShiftCountdown(
        gameId: widget.gameId,
        currentSeconds: nextShift.actualSeconds,
        shiftLengthSeconds: _shiftLengthSeconds,
        matchupTitle: matchupTitle,
        shiftNumber: shiftNumber,
      );
    }

    // Set up shift end notification if there's remaining time
    final remaining = _shiftLengthSeconds - nextShift.actualSeconds;
    if (remaining > 0) {
      final when = DateTime.now().add(Duration(seconds: remaining));
      try {
        await NotificationService.instance.scheduleShiftEnd(
          gameId: widget.gameId,
          at: when,
        );
      } catch (e) {
        // Notification scheduling can fail in some environments
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Shift started! ($e)'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // No future shift-end notification if already at/over time
      await NotificationService.instance.cancelShiftEnd(widget.gameId);
    }

    // Create the next shift after this one so coaches can plan ahead
    final nextShiftStart = nextShift.startSeconds + _shiftLengthSeconds;
    final hasNextShiftAlready =
        await db.nextShiftAfter(widget.gameId, nextShift.startSeconds) != null;

    if (!hasNextShiftAlready) {
      final nextPositions = await _positionsForNextShift(db);
      await db.createAutoShift(
        gameId: widget.gameId,
        startSeconds: nextShiftStart,
        positions: nextPositions,
        activate: false, // Don't make it current, just create it for planning
      );
    }

    // Scroll to the newly current shift
    if (_shiftsListKey.currentState != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _shiftsListKey.currentState?.scrollToShift(nextShift.id);
        }
      });
    }
  }
}

class _ShiftsList extends StatefulWidget {
  const _ShiftsList({
    super.key,
    required this.shifts,
    required this.shiftNumbers,
    required this.currentShiftId,
    required this.nextShiftId,
    required this.playersById,
    required this.db,
    this.onRemovePlayer,
    required this.getPositionAbbreviation,
  });

  final List<Shift> shifts;
  final Map<int, int> shiftNumbers;
  final int? currentShiftId;
  final int? nextShiftId;
  final Map<int, Player> playersById;
  final AppDb db;
  final Future<void> Function(Shift shift, PlayerShift assignment)?
  onRemovePlayer;
  final String Function(String) getPositionAbbreviation;

  @override
  State<_ShiftsList> createState() => _ShiftsListState();
}

class _ShiftsListState extends State<_ShiftsList> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Start at the current shift if available
    final initialIndex =
        widget.currentShiftId != null && widget.shifts.isNotEmpty
        ? widget.shifts.indexWhere((shift) => shift.id == widget.currentShiftId)
        : 0;
    _pageController = PageController(
      viewportFraction: 1.0,
      initialPage: initialIndex >= 0 ? initialIndex : 0,
    );
  }

  void scrollToShift(int shiftId) {
    if (!_pageController.hasClients || widget.shifts.isEmpty) return;

    final index = widget.shifts.indexWhere((shift) => shift.id == shiftId);
    if (index != -1) {
      _pageController.jumpToPage(index);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shifts.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 280, // Fixed height for horizontal scrolling
      child: PageView.builder(
        padEnds: false, // Allow pages to start from the edge
        controller: _pageController,
        itemCount: widget.shifts.length,
        itemBuilder: (context, index) {
          final shift = widget.shifts[index];
          final isCurrent = shift.id == widget.currentShiftId;
          final isNext =
              widget.nextShiftId != null && shift.id == widget.nextShiftId;
          final order = widget.shiftNumbers[shift.id];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            child: _ShiftDetailsPage(
              key: ValueKey(shift.id),
              shift: shift,
              order: order,
              isCurrent: isCurrent,
              isNext: isNext,
              playersById: widget.playersById,
              db: widget.db,
              onRemovePlayer: isCurrent ? widget.onRemovePlayer : null,
              getPositionAbbreviation: widget.getPositionAbbreviation,
            ),
          );
        },
      ),
    );
  }
}

class _ShiftDetailsPage extends StatelessWidget {
  const _ShiftDetailsPage({
    super.key,
    required this.shift,
    required this.order,
    required this.isCurrent,
    required this.isNext,
    required this.playersById,
    required this.db,
    this.onRemovePlayer,
    required this.getPositionAbbreviation,
  });

  final Shift shift;
  final int? order;
  final bool isCurrent;
  final bool isNext;
  final Map<int, Player> playersById;
  final AppDb db;
  final Future<void> Function(Shift shift, PlayerShift assignment)?
  onRemovePlayer;
  final String Function(String) getPositionAbbreviation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = isCurrent
        ? colorScheme.primaryContainer
        : isNext
        ? colorScheme.secondaryContainer
        : theme.cardColor;
    final onBackgroundColor = isCurrent
        ? colorScheme.onPrimaryContainer
        : isNext
        ? colorScheme.onSecondaryContainer
        : theme.textTheme.bodyMedium?.color;

    return Card(
      margin: EdgeInsets.zero,
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Shift ${order ?? '-'}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onBackgroundColor,
                        fontWeight: isCurrent ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    Chip(
                      label: const Text('Current'),
                      visualDensity: VisualDensity.compact,
                      labelStyle: theme.textTheme.labelSmall?.copyWith(
                        color: onBackgroundColor,
                      ),
                      backgroundColor: backgroundColor,
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: onBackgroundColor ?? theme.dividerColor,
                        ),
                      ),
                    )
                  else if (isNext)
                    Tooltip(
                      message: 'Regenerate shift with current attendance',
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.refresh, color: onBackgroundColor),
                        onPressed: () async {
                          // Get the game to find team ID
                          final game = await db.getGame(shift.gameId);
                          if (game == null) return;

                          // Get currently present players for the game
                          final presentPlayers = await db.presentPlayersForGame(
                            shift.gameId,
                            game.teamId,
                          );

                          // If no present players, we can't regenerate
                          if (presentPlayers.isEmpty) return;

                          // Use default positions based on number of present players
                          const allPositions = [
                            'GOALIE',
                            'RIGHT_DEFENSE',
                            'LEFT_DEFENSE',
                            'CENTER_FORWARD',
                            'RIGHT_FORWARD',
                            'LEFT_FORWARD',
                          ];

                          final positions = allPositions
                              .take(
                                presentPlayers.length.clamp(
                                  1,
                                  allPositions.length,
                                ),
                              )
                              .toList();

                          await db.createAutoShift(
                            gameId: shift.gameId,
                            startSeconds: shift.startSeconds,
                            positions: positions,
                            activate: false,
                            forceReassign: true,
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: onBackgroundColor,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _hhmmss(shift.actualSeconds),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onBackgroundColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              // Show notes except for formation helper text and auto-generated labels
              if (((shift.notes ?? '').isNotEmpty) &&
                  !(shift.notes ?? '').startsWith('Formation: ') &&
                  !(shift.notes ?? '').startsWith('Auto #')) ...[
                const SizedBox(height: 12),
                Text(
                  shift.notes!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onBackgroundColor,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Divider(color: onBackgroundColor?.withValues(alpha: 0.2)),
              const SizedBox(height: 8),
              StreamBuilder<List<PlayerShift>>(
                stream: db.watchAssignments(shift.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final assignments = snapshot.data ?? const <PlayerShift>[];
                  if (assignments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No players assigned yet.'),
                    );
                  }

                  // Determine a consistent order based on earliest assignment id per position.
                  final firstIdPerPosition = <String, int>{};
                  for (final a in assignments) {
                    final prev = firstIdPerPosition[a.position];
                    if (prev == null || a.id < prev) {
                      firstIdPerPosition[a.position] = a.id;
                    }
                  }
                  final sorted = [...assignments]
                    ..sort((a, b) {
                      final ai = firstIdPerPosition[a.position] ?? a.id;
                      final bi = firstIdPerPosition[b.position] ?? b.id;
                      if (ai != bi) return ai.compareTo(bi);
                      return a.id.compareTo(b.id);
                    });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header showing player count
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Text(
                              'Players (${assignments.length})',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: onBackgroundColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.people,
                              size: 16,
                              color: onBackgroundColor,
                            ),
                          ],
                        ),
                      ),
                      // Players grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3.2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          final assignment = sorted[index];
                          final player = playersById[assignment.playerId];

                          if (player == null) {
                            // Fallback for missing player data
                            final chip = InputChip(
                              label: Text(
                                '${assignment.position}: Player #${assignment.playerId}',
                              ),
                              onDeleted: onRemovePlayer == null
                                  ? null
                                  : () async {
                                      await onRemovePlayer!(shift, assignment);
                                    },
                            );
                            return onRemovePlayer == null
                                ? chip
                                : Tooltip(
                                    message: 'Remove from shift',
                                    child: chip,
                                  );
                          }

                          return PlayerPanel(
                            player: player,
                            type: PlayerPanelType.shift,
                            position: assignment.position,
                            playingTime: shift
                                .actualSeconds, // Use shift duration as playing time
                            getPositionAbbreviation: getPositionAbbreviation,
                            onTap: onRemovePlayer == null
                                ? null
                                : () async {
                                    await onRemovePlayer!(shift, assignment);
                                  },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _hhmmss(int s) {
  final h = (s ~/ 3600).toString().padLeft(2, '0');
  final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
  final sec = (s % 60).toString().padLeft(2, '0');
  return '$h:$m:$sec';
}

String _hhmmssSigned(int signedSeconds) {
  if (signedSeconds >= 0) return _hhmmss(signedSeconds);
  final abs = -signedSeconds;
  return '-${_hhmmss(abs)}';
}

String _formatDateTime(DateTime dt) {
  final year = dt.year.toString().padLeft(4, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final day = dt.day.toString().padLeft(2, '0');
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$year-$month-$day • $hour:$minute';
}

String _formatTimeRemaining(int seconds) {
  if (seconds <= 0) return '0:00';
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
}

enum _GameMenuAction {
  home,
  edit,
  lineup,
  metricsView,
  metricsInput,
  attendance,
  reset,
  endGame,
}

// (Play Time chart widgets moved to Metrics screen)
