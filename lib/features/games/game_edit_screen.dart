import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

class GameEditScreen extends ConsumerStatefulWidget {
  final int gameId;
  const GameEditScreen({super.key, required this.gameId});
  @override
  ConsumerState<GameEditScreen> createState() => _GameEditScreenState();
}

class _GameEditScreenState extends ConsumerState<GameEditScreen> {
  final _opp = TextEditingController();
  DateTime? _start;
  int? _teamId;
  List<Player> _players = <Player>[];
  final Set<int> _presentPlayerIds = <int>{};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(dbProvider);
    final game = await db.getGame(widget.gameId);
    if (!mounted || game == null) {
      setState(() => _loading = false);
      return;
    }

    final playersFuture = db.getPlayersByTeam(game.teamId);
    final attendanceFuture = db.watchAttendance(widget.gameId).first;

    final players = await playersFuture;
    final attendance = await attendanceFuture;
    if (!mounted) return;

    final presentIds = attendance.isEmpty
        ? players.where((p) => p.isPresent).map((p) => p.id)
        : attendance.where((a) => a.isPresent).map((a) => a.playerId);

    players.sort((a, b) {
      final last = a.lastName.compareTo(b.lastName);
      if (last != 0) return last;
      return a.firstName.compareTo(b.firstName);
    });

    setState(() {
      _teamId = game.teamId;
      _opp.text = game.opponent ?? '';
      _start = game.startTime ?? DateTime.now();
      _players = players;
      _presentPlayerIds
        ..clear()
        ..addAll(presentIds);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _opp.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'No date';
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Game')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _opp,
                    decoration: const InputDecoration(labelText: 'Opponent'),
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Text(_formatDateTime(_start))),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () async {
                                final now = _start ?? DateTime.now();
                                final date = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                  initialDate: now,
                                );
                                if (!context.mounted || date == null) return;
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(now),
                                );
                                if (!mounted) return;
                                final dt = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time?.hour ?? now.hour,
                                  time?.minute ?? now.minute,
                                );
                                setState(() => _start = dt);
                              },
                        child: const Text('Pick date/time'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _players.isEmpty
                        ? const Center(
                            child: Text('No players found for this team.'),
                          )
                        : ListView.separated(
                            itemCount: _players.length,
                            separatorBuilder: (_, __) => const Divider(height: 0),
                            itemBuilder: (_, index) {
                              final player = _players[index];
                              final present = _presentPlayerIds.contains(player.id);
                              return SwitchListTile(
                                title: Text('${player.firstName} ${player.lastName}'),
                                subtitle: Text('Player ID: ${player.id}'),
                                value: present,
                                onChanged: _saving
                                    ? null
                                    : (value) {
                                        setState(() {
                                          if (value) {
                                            _presentPlayerIds.add(player.id);
                                          } else {
                                            _presentPlayerIds.remove(player.id);
                                          }
                                        });
                                      },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save'),
                    onPressed: _saving
                        ? null
                        : () async {
                            if (_teamId == null) return;
                            setState(() => _saving = true);
                            await db.updateGame(
                              id: widget.gameId,
                              opponent: _opp.text.trim(),
                              startTime: _start,
                            );
                            for (final player in _players) {
                              final present = _presentPlayerIds.contains(player.id);
                              await db.setAttendance(
                                gameId: widget.gameId,
                                playerId: player.id,
                                isPresent: present,
                              );
                            }
                            if (!context.mounted) return;
                            context.go('/game/${widget.gameId}');
                          },
                  ),
                ],
              ),
            ),
    );
  }
}
