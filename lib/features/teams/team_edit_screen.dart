import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class TeamEditScreen extends ConsumerStatefulWidget {
  final int teamId;
  const TeamEditScreen({super.key, required this.teamId});
  @override
  ConsumerState<TeamEditScreen> createState() => _TeamEditScreenState();
}

class _TeamEditScreenState extends ConsumerState<TeamEditScreen> {
  final _name = TextEditingController();
  final _shiftMinutes = TextEditingController(text: '5');
  final _halfMinutes = TextEditingController(text: '20');
  String _teamMode = 'shift';

  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    db.getTeam(widget.teamId).then((team) {
      if (!mounted || team == null) return;
      setState(() {
        _name.text = team.name;
        _teamMode = team.teamMode;
      });
    });
    db.getTeamShiftLengthSeconds(widget.teamId).then((secs) {
      if (!mounted) return;
      final mins = (secs ~/ 60);
      setState(() => _shiftMinutes.text = mins.toString());
    });
    db.getTeamHalfDurationSeconds(widget.teamId).then((secs) {
      if (!mounted) return;
      final mins = (secs ~/ 60);
      setState(() => _halfMinutes.text = mins.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Team')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Team name'),
            ),
            const SizedBox(height: 16),

            // Team Mode Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Mode',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: Radio<String>(
                        value: 'shift',
                        groupValue: _teamMode,
                        onChanged: (value) =>
                            setState(() => _teamMode = value!),
                      ),
                      title: const Text('Shift Mode'),
                      subtitle: const Text(
                        'Timed shifts with automatic rotations',
                      ),
                      onTap: () => setState(() => _teamMode = 'shift'),
                    ),
                    ListTile(
                      leading: Radio<String>(
                        value: 'traditional',
                        groupValue: _teamMode,
                        onChanged: (value) =>
                            setState(() => _teamMode = value!),
                      ),
                      title: const Text('Traditional Mode'),
                      subtitle: const Text(
                        'Manual substitutions with playing time tracking',
                      ),
                      onTap: () => setState(() => _teamMode = 'traditional'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mode-specific settings
            if (_teamMode == 'shift') ...[
              TextField(
                controller: _shiftMinutes,
                decoration: const InputDecoration(
                  labelText: 'Default shift length (minutes)',
                ).copyWith(helperText: 'Used when auto-creating next shifts'),
                keyboardType: TextInputType.number,
              ),
            ] else ...[
              TextField(
                controller: _halfMinutes,
                decoration: const InputDecoration(
                  labelText: 'Half duration (minutes)',
                ).copyWith(helperText: 'Duration of each half of the game'),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: () async {
                final name = _name.text.trim();
                if (name.isEmpty) return;

                await db.updateTeamName(widget.teamId, name);
                await db.setTeamMode(widget.teamId, _teamMode);

                if (_teamMode == 'shift') {
                  final mins = int.tryParse(_shiftMinutes.text.trim());
                  if (mins != null && mins > 0) {
                    await db.setTeamShiftLengthSeconds(
                      widget.teamId,
                      mins * 60,
                    );
                  }
                } else {
                  final mins = int.tryParse(_halfMinutes.text.trim());
                  if (mins != null && mins > 0) {
                    await db.setTeamHalfDurationSeconds(
                      widget.teamId,
                      mins * 60,
                    );
                  }
                }

                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
