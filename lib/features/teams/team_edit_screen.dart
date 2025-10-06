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

  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    db.getTeam(widget.teamId).then((team) {
      if (!mounted || team == null) return;
      setState(() {
        _name.text = team.name;
      });
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
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Team name')),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: () async {
                final name = _name.text.trim();
                if (name.isEmpty) return;
                await db.updateTeamName(widget.teamId, name);
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
