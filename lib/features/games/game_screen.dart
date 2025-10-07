import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/positions.dart';
import '../../data/services/stopwatch_service.dart';
import '../../data/services/notification_service.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int gameId;
  const GameScreen({super.key, required this.gameId});
  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final ValueNotifier<int> _secondsNotifier;
  late final ProviderSubscription<int> _stopwatchSubscription;
  bool _isRunning = false;
  int _lastTickSeconds = 0;
  int? _currentShiftId;
  int _currentShiftStartSeconds = 0;
  bool _initialShiftCreated = false;
  bool _creatingInitialShift = false;
  final GlobalKey<_ShiftPagerState> _shiftPagerKey =
      GlobalKey<_ShiftPagerState>();
  int _shiftLengthSeconds = 300;
  int? _shiftLenForTeamId;
  bool _alertedThisShift = false;

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
    _lastTickSeconds = _secondsNotifier.value;
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

  @override
  void dispose() {
    _stopwatchSubscription.close();
    _secondsNotifier.dispose();
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
    // Prefer using positions from the current (or last) shift.
    if (_currentShiftId != null) {
      return _positionsFromShiftId(db, _currentShiftId!);
    }
    final shifts = await db.watchGameShifts(widget.gameId).first;
    if (shifts.isNotEmpty) {
      return _positionsFromShiftId(db, shifts.last.id);
    }
    return kPositions;
  }

  Future<void> _handleTick(AppDb db, int seconds) async {
    if (_isRunning && _currentShiftId != null) {
      final delta = seconds - _lastTickSeconds;
      if (delta > 0) {
        await db.incrementShiftDuration(_currentShiftId!, delta);
      }
      // Alert once when countdown reaches zero
      if (!_alertedThisShift && seconds >= _shiftLengthSeconds) {
        _alertedThisShift = true;
        // Haptic + system click, and a brief snackbar notification
        try {
          HapticFeedback.heavyImpact();
        } catch (_) {}
        try {
          SystemSound.play(SystemSoundType.click);
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shift time! Prepare to change.')),
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
          PopupMenuButton<_GameMenuAction>(
            onSelected: (value) async {
              switch (value) {
                case _GameMenuAction.edit:
                  if (!mounted) return;
                  context.push('/game/${widget.gameId}/edit');
                  break;
                case _GameMenuAction.lineup:
                  if (!mounted) return;
                  context.push('/game/${widget.gameId}/formation');
                  break;
                case _GameMenuAction.metrics:
                  if (!mounted) return;
                  context.push('/game/${widget.gameId}/metrics');
                  break;
                case _GameMenuAction.attendance:
                  if (!mounted) return;
                  context.push('/game/${widget.gameId}/attendance');
                  break;
                case _GameMenuAction.reset:
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
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _GameMenuAction.edit,
                child: Text('Edit game'),
              ),
              PopupMenuItem(
                value: _GameMenuAction.lineup,
                child: Text('Formation'),
              ),
              PopupMenuItem(
                value: _GameMenuAction.metrics,
                child: Text('Metrics'),
              ),
              PopupMenuItem(
                value: _GameMenuAction.attendance,
                child: Text('Attendance'),
              ),
              PopupMenuItem(
                value: _GameMenuAction.reset,
                child: Text('Reset stopwatch'),
              ),
            ],
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
                    _currentShiftId = game.currentShiftId;

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
                        // Compute next shift label number
                        final int nextShiftNumber = () {
                          if (nextShiftId != null) {
                            return shiftNumbers[nextShiftId] ??
                                (chronological.length + 1);
                          }
                          if (currentShift != null) {
                            final currentOrder =
                                shiftNumbers[currentShift.id] ??
                                (chronological.indexOf(currentShift) + 1);
                            return currentOrder + 1;
                          }
                          return (chronological.length + 1);
                        }();

                        final columnChildren = <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: ValueListenableBuilder<int>(
                              valueListenable: _secondsNotifier,
                              builder: (context, seconds, _) {
                                final remaining = _shiftLengthSeconds - seconds;
                                final over = remaining <= 0;
                                final flashOn = over && ((-remaining) % 2 == 0);
                                final theme = Theme.of(context);
                                final baseline =
                                    theme.colorScheme.surfaceContainerHighest;
                                final panelColor = over
                                    ? (flashOn ? Colors.red.shade800 : baseline)
                                    : baseline;
                                return Card(
                                  color: panelColor,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Center(
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            child: Text(
                                              _hhmmssSigned(remaining),
                                              key: ValueKey(remaining),
                                              style: theme
                                                  .textTheme
                                                  .displaySmall
                                                  ?.copyWith(
                                                    fontFeatures: const [
                                                      FontFeature.tabularFigures(),
                                                    ],
                                                    letterSpacing: 1.0,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Align(
                                          alignment: Alignment.center,
                                          child: Tooltip(
                                            message: 'Jump to current shift',
                                            child: TextButton.icon(
                                              onPressed:
                                                  game.currentShiftId == null
                                                  ? null
                                                  : () => _shiftPagerKey
                                                        .currentState
                                                        ?.queueFocus(
                                                          game.currentShiftId!,
                                                        ),
                                              icon: const Icon(
                                                Icons.flag_circle,
                                              ),
                                              label: Text(() {
                                                final id = game.currentShiftId;
                                                if (id == null)
                                                  return 'Current shift';
                                                final order = shiftNumbers[id];
                                                return order == null
                                                    ? 'Current shift'
                                                    : 'Current shift #$order';
                                              }()),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: OverflowBar(
                              alignment: MainAxisAlignment.center,
                              overflowAlignment: OverflowBarAlignment.center,
                              spacing: 12,
                              overflowSpacing: 8,
                              children: [
                                if (!_isRunning)
                                  Tooltip(
                                    message: 'Start timer',
                                    child: FilledButton.icon(
                                      icon: const Icon(
                                        Icons.play_arrow_rounded,
                                      ),
                                      label: const Text('Start'),
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
                                        final currentId = game?.currentShiftId;
                                        if (currentId != null) {
                                          shiftId = currentId;
                                        } else {
                                          final positions =
                                              await _positionsForNextShift(db);
                                          shiftId = await db.createAutoShift(
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

                                        // Pre-create the upcoming shift so the pager has it ready
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
                                              await _positionsFromShiftId(
                                                db,
                                                shiftId,
                                              );
                                          await db.createAutoShift(
                                            gameId: widget.gameId,
                                            startSeconds: upcomingStart,
                                            positions: nextPositions,
                                            activate: false,
                                          );
                                        }
                                        // Set metadata for notification (team vs opponent, shift length)
                                        final gameForMeta = await db.getGame(
                                          widget.gameId,
                                        );
                                        if (gameForMeta != null) {
                                          final team = await db.getTeam(
                                            gameForMeta.teamId,
                                          );
                                          final teamName = team?.name ?? 'Team';
                                          final opponent =
                                              gameForMeta.opponent ?? '';
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
                                        await stopwatchCtrl.start();
                                        if (!mounted) return;
                                        setState(() {
                                          _currentShiftId = shiftId;
                                          _isRunning = true;
                                          _lastTickSeconds =
                                              _secondsNotifier.value;
                                          _alertedThisShift =
                                              _secondsNotifier.value >=
                                              _shiftLengthSeconds;
                                        });
                                        final remaining =
                                            _shiftLengthSeconds -
                                            _secondsNotifier.value;
                                        final when = DateTime.now().add(
                                          Duration(
                                            seconds: remaining > 0
                                                ? remaining
                                                : 0,
                                          ),
                                        );
                                        await NotificationService.instance
                                            .cancelShiftEnd(widget.gameId);
                                        await NotificationService.instance
                                            .scheduleShiftEnd(
                                              gameId: widget.gameId,
                                              at: when,
                                            );
                                      },
                                    ),
                                  ),
                                if (_isRunning)
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
                                        setState(() {
                                          _isRunning = false;
                                        });
                                      },
                                    ),
                                  ),
                                // Reset moved to kebab menu
                                Tooltip(
                                  message: 'End current and start next shift',
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    label: Text(
                                      'Start Shift #$nextShiftNumber',
                                    ),
                                    onPressed: () async {
                                      await _advanceToNextShift(
                                        db,
                                        resumeRunning: true,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                          // Buttons to prepare/regenerate next shift removed; handled in pager

                          // (Play Time chart moved to Metrics screen)

                          columnChildren.add(
                            Expanded(
                              child: _ShiftPager(
                                key: _shiftPagerKey,
                                shifts: chronological,
                                shiftNumbers: shiftNumbers,
                                currentShiftId: game.currentShiftId,
                                nextShiftId: nextShiftId,
                                playersById: playersById,
                                db: db,
                                shiftLengthSeconds: _shiftLengthSeconds,
                                onRemovePlayer: (shift, assignment) =>
                                    _handleRemovePlayerFromShift(
                                      context,
                                      db,
                                      shift,
                                      assignment,
                                    ),
                                onPrepareNextShift: () async {
                                  final cs = currentShift;
                                  if (cs == null) return;
                                  final nextStartSeconds =
                                      cs.startSeconds + _shiftLengthSeconds;
                                  final positions = await _positionsFromShiftId(
                                    db,
                                    cs.id,
                                  );
                                  final shiftId = await db.createAutoShift(
                                    gameId: widget.gameId,
                                    startSeconds: nextStartSeconds,
                                    positions: positions,
                                    activate: false,
                                  );
                                  if (!mounted) return;
                                  // Ensure pager focuses the newly created next shift
                                  _shiftPagerKey.currentState?.queueFocus(
                                    shiftId,
                                  );
                                  setState(() {});
                                },
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
      setState(() {
        _initialShiftCreated = true;
        _currentShiftId = newShiftId;
        _currentShiftStartSeconds = 0;
      });
    } finally {
      _creatingInitialShift = false;
    }
  }

  Future<int> _advanceToNextShift(
    AppDb db, {
    required bool resumeRunning,
  }) async {
    final stopwatchCtrl = ref.read(stopwatchProvider(widget.gameId).notifier);
    final elapsed = _secondsNotifier.value;
    final actualStartSeconds = _currentShiftStartSeconds + elapsed;

    final prepared = await db.nextShiftAfter(
      widget.gameId,
      _currentShiftStartSeconds,
    );
    if (prepared != null && prepared.startSeconds != actualStartSeconds) {
      await db.updateShiftStartSeconds(prepared.id, actualStartSeconds);
    }

    final positions = await _positionsForNextShift(db);
    final nextShiftId = await db.createAutoShift(
      gameId: widget.gameId,
      startSeconds: actualStartSeconds,
      positions: positions,
    );

    await stopwatchCtrl.reset();
    if (resumeRunning) {
      final gameForMeta = await db.getGame(widget.gameId);
      if (gameForMeta != null) {
        final team = await db.getTeam(gameForMeta.teamId);
        final teamName = team?.name ?? 'Team';
        final opponent = gameForMeta.opponent ?? '';
        final shiftNumber = await _shiftNumberFor(db, nextShiftId);
        await stopwatchCtrl.setMeta(
          teamName: teamName,
          opponent: opponent,
          shiftLengthSeconds: _shiftLengthSeconds,
          shiftNumber: shiftNumber,
        );
      }
      await stopwatchCtrl.start();
    }

    if (!mounted) return nextShiftId;

    setState(() {
      _currentShiftId = nextShiftId;
      _currentShiftStartSeconds = actualStartSeconds;
      _lastTickSeconds = 0;
      _isRunning = resumeRunning;
      _alertedThisShift = false;
    });
    // _shiftPagerKey.currentState?.queueFocus(nextShiftId); // removed: method not defined

    // Also pre-create the following shift to avoid pager sentinel and jumps
    final upcomingStart = actualStartSeconds + _shiftLengthSeconds;
    final maybeExisting = await db.nextShiftAfter(
      widget.gameId,
      actualStartSeconds,
    );
    if (maybeExisting == null || maybeExisting.startSeconds != upcomingStart) {
      final nextPositions = await _positionsFromShiftId(db, nextShiftId);
      await db.createAutoShift(
        gameId: widget.gameId,
        startSeconds: upcomingStart,
        positions: nextPositions,
        activate: false,
      );
    }

    if (resumeRunning) {
      await NotificationService.instance.cancelShiftEnd(widget.gameId);
      final when = DateTime.now().add(Duration(seconds: _shiftLengthSeconds));
      await NotificationService.instance.scheduleShiftEnd(
        gameId: widget.gameId,
        at: when,
      );
    }

    return nextShiftId;
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
    if (!mounted) return;
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
    if (!mounted) return;
    if (!confirmed) return;
    await db.removePlayerFromShift(
      shiftId: shift.id,
      playerId: assignment.playerId,
      position: assignment.position,
      gameId: shift.gameId,
      startSeconds: shift.startSeconds,
    );
    if (!mounted) return;
    setState(() {});
  }
}

class _ShiftPager extends StatefulWidget {
  const _ShiftPager({
    super.key,
    required this.shifts,
    required this.shiftNumbers,
    required this.currentShiftId,
    required this.nextShiftId,
    required this.playersById,
    required this.db,
    required this.shiftLengthSeconds,
    this.onRemovePlayer,
    required this.onPrepareNextShift,
  });

  final List<Shift> shifts;
  final Map<int, int> shiftNumbers;
  final int? currentShiftId;
  final int? nextShiftId;
  final Map<int, Player> playersById;
  final AppDb db;
  final int shiftLengthSeconds;
  final Future<void> Function(Shift shift, PlayerShift assignment)?
  onRemovePlayer;
  final Future<void> Function() onPrepareNextShift;

  @override
  State<_ShiftPager> createState() => _ShiftPagerState();
}

class _ShiftPagerState extends State<_ShiftPager> {
  late final PageController _controller;
  int _pageIndex = 0;
  int? _pendingFocus;
  bool _creatingNext = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpToPage(int index) {
    if (!_controller.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.jumpToPage(index);
      });
    } else {
      _controller.jumpToPage(index);
    }
  }

  void queueFocus(int? shiftId) {
    if (shiftId == null) return;
    _pendingFocus = shiftId;
    _attemptFocus();
  }

  void _attemptFocus() {
    final target = _pendingFocus;
    if (target == null) return;
    final idx = widget.shifts.indexWhere((s) => s.id == target);
    if (idx == -1) return;
    _pendingFocus = null;
    if (_pageIndex != idx) {
      setState(() => _pageIndex = idx);
    }
    _jumpToPage(idx);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shifts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine whether to expose a sentinel page to allow creating the next shift by swiping right
    final total = widget.shifts.length;
    final addSentinel = _shouldAddSentinel(
      widget.shifts,
      widget.currentShiftId,
    );
    final effectiveCount = total + (addSentinel ? 1 : 0);
    final clamped = _pageIndex.clamp(0, effectiveCount - 1);
    if (clamped != _pageIndex) {
      _pageIndex = clamped;
    }

    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: effectiveCount,
          onPageChanged: (index) {
            setState(() => _pageIndex = index);
          },
          itemBuilder: (context, index) {
            if (addSentinel && index == total) {
              if (!_creatingNext) {
                _creatingNext = true;
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await widget.onPrepareNextShift();
                  if (mounted) {
                    setState(() {
                      _creatingNext = false;
                    });
                  } else {
                    _creatingNext = false;
                  }
                });
              }
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Preparing next shift…'),
                    ],
                  ),
                ),
              );
            }
            final shift = widget.shifts[index];
            final isCurrent = shift.id == widget.currentShiftId;
            final isNext =
                widget.nextShiftId != null && shift.id == widget.nextShiftId;
            final order = widget.shiftNumbers[shift.id];
            return _ShiftDetailsPage(
              shift: shift,
              order: order,
              isCurrent: isCurrent,
              isNext: isNext,
              playersById: widget.playersById,
              db: widget.db,
              onRemovePlayer: isCurrent ? widget.onRemovePlayer : null,
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 8 + (bottomPad > 0 ? bottomPad / 2 : 0),
          child: IgnorePointer(
            ignoring: true,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_pageIndex + 1} / $effectiveCount',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _shouldAddSentinel(List<Shift> shifts, int? currentShiftId) {
    if (currentShiftId == null) return false;
    final idx = shifts.indexWhere((s) => s.id == currentShiftId);
    if (idx == -1) return false;
    final current = shifts[idx];
    final nextStart = current.startSeconds + widget.shiftLengthSeconds;
    final hasNext = shifts.any((s) => s.startSeconds == nextStart);
    return !hasNext;
  }
}

class _ShiftDetailsPage extends StatelessWidget {
  const _ShiftDetailsPage({
    required this.shift,
    required this.order,
    required this.isCurrent,
    required this.isNext,
    required this.playersById,
    required this.db,
    this.onRemovePlayer,
  });

  final Shift shift;
  final int? order;
  final bool isCurrent;
  final bool isNext;
  final Map<int, Player> playersById;
  final AppDb db;
  final Future<void> Function(Shift shift, PlayerShift assignment)?
  onRemovePlayer;

  Future<List<String>> _positionsForShift(Shift shift) async {
    final assignments = await db.getAssignments(shift.id);
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Card(
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
                    else if (isNext) ...[
                      Chip(
                        label: const Text('Next'),
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
                      ),
                      Tooltip(
                        message: 'Regenerate next shift',
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.refresh, color: onBackgroundColor),
                          onPressed: () async {
                            final positions = await _positionsForShift(shift);
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
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sorted.map((assignment) {
                        final player = playersById[assignment.playerId];
                        final name = player == null
                            ? 'Player #${assignment.playerId}'
                            : '${player.firstName} ${player.lastName}';
                        final chip = InputChip(
                          label: Text('${assignment.position}: $name'),
                          onDeleted: onRemovePlayer == null
                              ? null
                              : () async {
                                  await onRemovePlayer!(shift, assignment);
                                },
                        );
                        if (onRemovePlayer == null) {
                          return chip;
                        }
                        return Tooltip(
                          message: 'Remove from shift',
                          child: chip,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
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

enum _GameMenuAction { edit, lineup, metrics, attendance, reset }

// (Play Time chart widgets moved to Metrics screen)
