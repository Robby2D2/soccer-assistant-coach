import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

class TeamFormationsScreen extends ConsumerStatefulWidget {
  final int teamId;
  const TeamFormationsScreen({super.key, required this.teamId});

  @override
  ConsumerState<TeamFormationsScreen> createState() => _TeamFormationsScreenState();
}

class _TeamFormationsScreenState extends ConsumerState<TeamFormationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _playerCountCtrl = TextEditingController(text: '6');
  int _count = 6;
  late List<TextEditingController> _positionCtrls;

  @override
  void initState() {
    super.initState();
    _positionCtrls = List.generate(_count, (i) => TextEditingController());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _playerCountCtrl.dispose();
    for (final c in _positionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateCount(int newCount) {
    if (newCount <= 0) return;
    setState(() {
      _count = newCount;
      if (_positionCtrls.length < _count) {
        final toAdd = _count - _positionCtrls.length;
        _positionCtrls.addAll(List.generate(toAdd, (i) => TextEditingController()));
      } else if (_positionCtrls.length > _count) {
        final extras = _positionCtrls.sublist(_count);
        for (final c in extras) {
          c.dispose();
        }
        _positionCtrls = _positionCtrls.sublist(0, _count);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Formation Builder')),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: StreamBuilder(
              stream: db.watchTeamFormations(widget.teamId),
              builder: (context, snapshot) {
                final formations = snapshot.data ?? const <Formation>[];
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: formations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final f = formations[index];
                    return ListTile(
                      title: Text(f.name),
                      subtitle: Text('${f.playerCount} players'),
                      trailing: IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete formation?'),
                                  content: Text('Delete "${f.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                          if (!confirm) return;
                          await db.deleteFormation(f.id);
                        },
                      ),
                      onTap: () async {
                        // Simple preview dialog
                        final positions = await db.getFormationPositions(f.id);
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(f.name),
                            content: SizedBox(
                              width: 320,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: positions
                                    .map((p) => Chip(label: Text(p.positionName)))
                                    .toList(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create new formation', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Formation name (e.g. 2-3-1)'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _playerCountCtrl,
                              decoration: const InputDecoration(labelText: 'Number of players'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (v) {
                                final parsed = int.tryParse(v);
                                if (parsed != null) _updateCount(parsed);
                              },
                              validator: (v) {
                                final parsed = int.tryParse(v ?? '');
                                if (parsed == null || parsed <= 0) return 'Enter a positive number';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Positions: $_count'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      for (var i = 0; i < _count; i++) ...[
                        TextFormField(
                          controller: _positionCtrls[i],
                          decoration: InputDecoration(labelText: 'Position ${i + 1} name'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Save formation'),
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;
                            final count = int.parse(_playerCountCtrl.text);
                            final positions = _positionCtrls.take(count).map((c) => c.text.trim()).toList();
                            await db.createFormation(
                              teamId: widget.teamId,
                              name: _nameCtrl.text.trim(),
                              playerCount: count,
                              positions: positions,
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Formation created')),
                            );
                            setState(() {
                              _nameCtrl.clear();
                              _playerCountCtrl.text = '6';
                              _updateCount(6);
                              for (final c in _positionCtrls) c.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

