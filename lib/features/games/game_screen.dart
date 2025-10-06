import 'package:flutter/foundation.dart';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/positions.dart';
import '../../data/services/stopwatch_service.dart';

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

  Future<void> _handleTick(AppDb db, int seconds) async {
    if (_isRunning && _currentShiftId != null) {
      final delta = seconds - _lastTickSeconds;
      if (delta > 0) {
        await db.incrementShiftDuration(_currentShiftId!, delta);
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
                    style: Theme.of(context).textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            );
          },
        ),
        actions: [
          PopupMenuButton<_GameMenuAction>(
            tooltip: 'Options',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case _GameMenuAction.edit:
                  context.push('/game/${widget.gameId}/edit');
                  break;
                case _GameMenuAction.lineup:
                  context.push('/game/${widget.gameId}/formation');
                  break;
                case _GameMenuAction.metrics:
                  context.push('/game/${widget.gameId}/metrics');
                  break;
                case _GameMenuAction.attendance:
                  context.push('/game/${widget.gameId}/attendance');
                  break;
                case _GameMenuAction.reset:
                  await ref
                      .read(
                        stopwatchProvider(
                          widget.gameId,
                        ).notifier,
                      )
                      .reset();
                  await db.endShiftAt(widget.gameId, 0);
                  if (!mounted) return;
                  setState(() {
                    _isRunning = false;
                    _currentShiftId = null;
                    _lastTickSeconds = 0;
                    _currentShiftStartSeconds = 0;
                  });
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

                        final theme = Theme.of(context);
                        // Compute next shift label number
                        final int nextShiftNumber = () {
                          if (nextShiftId != null) {
                            return shiftNumbers[nextShiftId] ?? (chronological.length + 1);
                          }
                          if (currentShift != null) {
                            final currentOrder = shiftNumbers[currentShift.id] ?? (chronological.indexOf(currentShift) + 1);
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
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ValueListenableBuilder<int>(
                                      valueListenable: _secondsNotifier,
                                      builder: (context, seconds, _) => Center(
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 200),
                                          child: Text(
                                            _hhmmss(seconds),
                                            key: ValueKey(seconds),
                                            style: theme.textTheme.displaySmall?.copyWith(
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                              letterSpacing: 1.0,
                                            ),
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
                                          onPressed: game.currentShiftId == null
                                              ? null
                                              : () => _shiftPagerKey.currentState
                                                  ?.queueFocus(game.currentShiftId!),
                                          icon: const Icon(Icons.flag_circle),
                                          label: Text(
                                            () {
                                              final id = game.currentShiftId;
                                              if (id == null) return 'Current shift';
                                              final order = shiftNumbers[id];
                                              return order == null
                                                  ? 'Current shift'
                                                  : 'Current shift #$order';
                                            }(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                                      icon: const Icon(Icons.play_arrow_rounded),
                                      label: const Text('Start'),
                                      onPressed: () async {
                                        final stopwatchCtrl = ref.read(
                                          stopwatchProvider(widget.gameId).notifier,
                                        );
                                        final game = await db.getGame(
                                          widget.gameId,
                                        );
                                        final int shiftId;
                                        final currentId = game?.currentShiftId;
                                        if (currentId != null) {
                                          shiftId = currentId;
                                        } else {
                                          shiftId = await db.createAutoShift(
                                            gameId: widget.gameId,
                                            startSeconds: _currentShiftStartSeconds,
                                            positions: kPositions,
                                          );
                                        }

                                        final shift = await db.getShift(shiftId);
                                        if (shift != null) {
                                          _currentShiftStartSeconds = shift.startSeconds;
                                        }
                                        await stopwatchCtrl.start();
                                        if (!mounted) return;
                                        setState(() {
                                          _currentShiftId = shiftId;
                                          _isRunning = true;
                                          _lastTickSeconds = _secondsNotifier.value;
                                        });
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
                                    label: Text('Start Shift #$nextShiftNumber'),
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
                                  final nextStartSeconds = cs.startSeconds + 300;
                                  final shiftId = await db.createAutoShift(
                                    gameId: widget.gameId,
                                    startSeconds: nextStartSeconds,
                                    positions: kPositions,
                                    activate: false,
                                  );
                                  if (!mounted) return;
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

    final nextShiftId = await db.createAutoShift(
      gameId: widget.gameId,
      startSeconds: actualStartSeconds,
      positions: kPositions,
    );

    await stopwatchCtrl.reset();
    if (resumeRunning) {
      await stopwatchCtrl.start();
    }

    if (!mounted) return nextShiftId;

    setState(() {
      _currentShiftId = nextShiftId;
      _currentShiftStartSeconds = actualStartSeconds;
      _lastTickSeconds = 0;
      _isRunning = resumeRunning;
    });
    _shiftPagerKey.currentState?.queueFocus(nextShiftId);

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
    this.onRemovePlayer,
    required this.onPrepareNextShift,
  });

  final List<Shift> shifts;
  final Map<int, int> shiftNumbers;
  final int? currentShiftId;
  final int? nextShiftId;
  final Map<int, Player> playersById;
  final AppDb db;
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
    _pageIndex = _initialIndex();
    _controller = PageController(initialPage: _pageIndex);
  }

  @override
  void didUpdateWidget(covariant _ShiftPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldHadSentinel = _shouldAddSentinel(oldWidget.shifts, oldWidget.currentShiftId);
    final newHasSentinel = _shouldAddSentinel(widget.shifts, widget.currentShiftId);

    if (!listEquals(
      _shiftIdList(oldWidget.shifts),
      _shiftIdList(widget.shifts),
    )) {
      _ensureValidIndex();

      // If we were viewing the sentinel page and it got replaced
      // by a real shift, keep the pager on the same index so it
      // shows the newly created shift instead of snapping back.
      if (oldHadSentinel && !newHasSentinel) {
        final sentinelIndex = oldWidget.shifts.length; // last index previously
        if (_pageIndex == sentinelIndex) {
          final int target = _pageIndex <= widget.shifts.length - 1
              ? _pageIndex
              : (widget.shifts.length - 1);
          _jumpToPage(target);
        }
      }
    }
    _attemptFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<int> _shiftIdList(List<Shift> shifts) => [for (final s in shifts) s.id];

  int _initialIndex() {
    if (widget.currentShiftId == null) return 0;
    final idx = widget.shifts.indexWhere((s) => s.id == widget.currentShiftId);
    return idx == -1 ? 0 : idx;
  }

  void _ensureValidIndex() {
    if (widget.shifts.isEmpty) {
      if (_pageIndex != 0) {
        setState(() => _pageIndex = 0);
      }
      return;
    }
    final maxIndex = widget.shifts.length - 1;
    if (_pageIndex > maxIndex) {
      setState(() => _pageIndex = maxIndex);
      _jumpToPage(maxIndex);
    }
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
    final addSentinel = _shouldAddSentinel(widget.shifts, widget.currentShiftId);
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
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_pageIndex + 1} / $effectiveCount',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
    final nextStart = current.startSeconds + 300;
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
                          side: BorderSide(color: onBackgroundColor ?? theme.dividerColor),
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
                          side: BorderSide(color: onBackgroundColor ?? theme.dividerColor),
                        ),
                      ),
                      Tooltip(
                        message: 'Regenerate next shift',
                        child: IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.refresh, color: onBackgroundColor),
                          onPressed: () async {
                            await db.createAutoShift(
                              gameId: shift.gameId,
                              startSeconds: shift.startSeconds,
                              positions: kPositions,
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
                    Icon(Icons.timer_outlined, color: onBackgroundColor, size: 18),
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
                if ((shift.notes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    shift.notes!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onBackgroundColor,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Divider(color: onBackgroundColor?.withOpacity(0.2)),
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
                    final sorted = [...assignments]
                      ..sort((a, b) {
                        final ai = kPositions.indexOf(a.position);
                        final bi = kPositions.indexOf(b.position);
                        final safeAi = ai == -1 ? kPositions.length : ai;
                        final safeBi = bi == -1 ? kPositions.length : bi;
                        return safeAi.compareTo(safeBi);
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
