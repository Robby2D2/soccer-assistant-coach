import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

class FormationEditScreen extends ConsumerStatefulWidget {
  final int teamId;
  final int? formationId;
  const FormationEditScreen({
    super.key,
    required this.teamId,
    this.formationId,
  });

  @override
  ConsumerState<FormationEditScreen> createState() =>
      _FormationEditScreenState();
}

class _FormationEditScreenState extends ConsumerState<FormationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _playerCountCtrl = TextEditingController(text: '6');
  int _count = 6;
  late List<TextEditingController> _positionCtrls;
  late List<TextEditingController> _abbreviationCtrls;
  bool _loading = false;
  bool _notFound = false;
  bool _showTemplates = false;

  @override
  void initState() {
    super.initState();
    _positionCtrls = List.generate(_count, (i) => TextEditingController());
    _abbreviationCtrls = List.generate(_count, (i) => TextEditingController());
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
        _abbreviationCtrls[i].text = positions[i].abbreviation;
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
    for (final c in _abbreviationCtrls) {
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
        _positionCtrls.addAll(
          List.generate(toAdd, (i) => TextEditingController()),
        );
        _abbreviationCtrls.addAll(
          List.generate(toAdd, (i) => TextEditingController()),
        );
      } else if (_positionCtrls.length > _count) {
        final positionExtras = _positionCtrls.sublist(_count);
        final abbreviationExtras = _abbreviationCtrls.sublist(_count);
        for (final c in positionExtras) {
          c.dispose();
        }
        for (final c in abbreviationExtras) {
          c.dispose();
        }
        _positionCtrls = _positionCtrls.sublist(0, _count);
        _abbreviationCtrls = _abbreviationCtrls.sublist(0, _count);
      }
    });
  }

  void _loadTemplate(FormationTemplate template) {
    setState(() {
      _nameCtrl.text = template.name;
      _playerCountCtrl.text = template.playerCount.toString();
      _updateCount(template.playerCount);
      for (var i = 0; i < template.positions.length && i < _count; i++) {
        _positionCtrls[i].text = template.positions[i];
        _abbreviationCtrls[i].text = template.abbreviations[i];
      }
      _showTemplates = false; // Hide templates after selecting one
    });
  }

  String _getFormationDescription(String formationName) {
    switch (formationName) {
      case '4-4-2':
        return 'Classic balanced formation';
      case '4-3-3':
        return 'Attacking formation with wingers';
      case '4-2-3-1':
        return 'Modern tactical formation';
      case '2-2-1':
        return 'Small-sided game formation';
      default:
        return 'Custom formation';
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    final isEdit = widget.formationId != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Formation' : 'New Formation')),
      floatingActionButton: _loading || _notFound
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final count = int.parse(_playerCountCtrl.text);
                final positions = _positionCtrls
                    .take(count)
                    .map((c) => c.text.trim())
                    .toList();
                final abbreviations = _abbreviationCtrls
                    .take(count)
                    .map((c) => c.text.trim())
                    .toList();
                if (isEdit) {
                  await db.updateFormation(
                    id: widget.formationId!,
                    name: _nameCtrl.text.trim(),
                    playerCount: count,
                    positions: positions,
                    abbreviations: abbreviations,
                  );
                } else {
                  await db.createFormation(
                    teamId: widget.teamId,
                    name: _nameCtrl.text.trim(),
                    playerCount: count,
                    positions: positions,
                    abbreviations: abbreviations,
                  );
                }
                // After async calls, ensure the specific BuildContext is still mounted
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEdit ? 'Formation updated' : 'Formation created',
                    ),
                  ),
                );
                context.pop();
              },
              icon: const Icon(Icons.save),
              label: Text(isEdit ? 'Save' : 'Create'),
            ),
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
                      // Template selection for new formations
                      if (!isEdit) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.sports_soccer),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Formation Templates',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _showTemplates = !_showTemplates;
                                        });
                                      },
                                      child: Text(
                                        _showTemplates ? 'Hide' : 'Show',
                                      ),
                                    ),
                                  ],
                                ),
                                if (_showTemplates) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Choose a template to get started:',
                                  ),
                                  const SizedBox(height: 8),
                                  ...FormationTemplates.getTemplates().map(
                                    (template) => Card(
                                      child: ListTile(
                                        title: Text(template.name),
                                        subtitle: Text(
                                          '${template.playerCount} players • ${_getFormationDescription(template.name)}',
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward,
                                        ),
                                        onTap: () => _loadTemplate(template),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Formation name (e.g. 2-3-1)',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter a name'
                            : null,
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
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (v) {
                                final parsed = int.tryParse(v);
                                if (parsed != null) {
                                  _updateCount(parsed);
                                }
                              },
                              validator: (v) {
                                final parsed = int.tryParse(v ?? '');
                                if (parsed == null || parsed <= 0) {
                                  return 'Enter a positive number';
                                }
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
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _positionCtrls[i],
                                decoration: InputDecoration(
                                  labelText: 'Position ${i + 1} name',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Enter a name'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _abbreviationCtrls[i],
                                decoration: const InputDecoration(
                                  labelText: 'Abbr.',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Enter abbreviation'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
