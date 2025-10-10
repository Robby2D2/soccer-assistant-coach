import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class PlayerEditScreen extends ConsumerStatefulWidget {
  final int playerId;
  const PlayerEditScreen({super.key, required this.playerId});
  @override
  ConsumerState<PlayerEditScreen> createState() => _PlayerEditScreenState();
}

class _PlayerEditScreenState extends ConsumerState<PlayerEditScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  bool _present = true;

  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    db.getPlayer(widget.playerId).then((p) {
      if (!mounted || p == null) return;
      setState(() {
        _first.text = p.firstName;
        _last.text = p.lastName;
        _present = p.isPresent;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Player')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _first,
              decoration: const InputDecoration(labelText: 'First name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _last,
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _present,
              title: const Text('Active'),
              onChanged: (v) => setState(() => _present = v),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: () async {
                final f = _first.text.trim();
                final l = _last.text.trim();
                if (f.isEmpty || l.isEmpty) return;
                await db.updatePlayer(
                  id: widget.playerId,
                  firstName: f,
                  lastName: l,
                  isPresent: _present,
                );
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
