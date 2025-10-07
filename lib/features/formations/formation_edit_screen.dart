import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

class FormationEditScreen extends ConsumerStatefulWidget {
  final int teamId;
  final int? formationId;
  const FormationEditScreen({super.key, required this.teamId, this.formationId});

  @override
  ConsumerState<FormationEditScreen> createState() => _FormationEditScreenState();
}

class _FormationEditScreenState extends ConsumerState<FormationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _playerCountCtrl = TextEditingController(text: '6');
  int _count = 6;
  late List<TextEditingController> _positionCtrls;
  bool _loading = false;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _positionCtrls = List.generate(_count, (i) => TextEditingController());
    if (widget.formationId != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final db = ref.read(dbProvider);
    final f = await db.getFormation(widget.formationId!);
    if (f == null) {
      setState(() {
        _notFound = true;
        _loading = false;
      });
      return;
    }
    final positions = await db.getFormationPositions(f.id);
    setState(() {
      _nameCtrl.text = f.name;
      _playerCountCtrl.text = f.playerCount.toString();
      _updateCount(f.playerCount);
      for (var i = 0; i < f.playerCount && i < positions.length; i++) {
        _positionCtrls[i].text = positions[i].positionName;
      }
      _loading = false;
    });
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
    final isEdit = widget.formationId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Formation' : 'New Formation')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notFound
              ? const Center(child: Text('Formation not found'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Formation name (e.g. 2-3-1)',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _playerCountCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Number of players',
                                  ),
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
                              decoration: InputDecoration(
                                labelText: 'Position ${i + 1} name',
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                            ),
                            const SizedBox(height: 8),
                          ],
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              icon: const Icon(Icons.save),
                              label: Text(isEdit ? 'Save changes' : 'Create formation'),
                              onPressed: () async {
                                if (!_formKey.currentState!.validate()) return;
                                final count = int.parse(_playerCountCtrl.text);
                                final positions = _positionCtrls.take(count).map((c) => c.text.trim()).toList();
                                if (isEdit) {
                                  await db.updateFormation(
                                    id: widget.formationId!,
                                    name: _nameCtrl.text.trim(),
                                    playerCount: count,
                                    positions: positions,
                                  );
                                } else {
                                  await db.createFormation(
                                    teamId: widget.teamId,
                                    name: _nameCtrl.text.trim(),
                                    playerCount: count,
                                    positions: positions,
                                  );
                                }
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(isEdit ? 'Formation updated' : 'Formation created')),
                                );
                                context.pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}

