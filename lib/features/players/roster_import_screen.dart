import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers.dart';
import '../../utils/csv.dart';

class RosterImportScreen extends ConsumerStatefulWidget {
  final int teamId;
  const RosterImportScreen({super.key, required this.teamId});
  @override
  ConsumerState<RosterImportScreen> createState() => _RosterImportScreenState();
}

class _RosterImportScreenState extends ConsumerState<RosterImportScreen> {
  final _text = TextEditingController();
  List<Map<String, String>> _rows = [];

  void _parse() {
    _rows = csvToPlayers(_text.text);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // Start with empty text field - no default parsing needed
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Import Roster CSV')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Paste CSV with header: firstName,lastName,jerseyNumber (jersey number is optional)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _text,
                expands: true,
                maxLines: null,
                minLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText:
                      'firstName,lastName,jerseyNumber\nJane,Doe,10\nJohn,Smith,\nAlex,Johnson,7',
                ),
                onChanged: (_) => _parse(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Preview: ${_rows.length} rows',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: ListView.builder(
                itemCount: _rows.length,
                itemBuilder: (_, i) {
                  final r = _rows[i];
                  return ListTile(
                    dense: true,
                    title: Text(
                      '${r['firstName']} ${r['lastName']}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    subtitle: Text(
                      'Jersey #: ${r['jerseyNumber'] ?? 'N/A'}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _rows.isEmpty
                  ? null
                  : () async {
                      for (final r in _rows) {
                        // Parse jersey number, handle empty or invalid values
                        int? jerseyNumber;
                        final jerseyStr = r['jerseyNumber']?.trim();
                        if (jerseyStr != null && jerseyStr.isNotEmpty) {
                          jerseyNumber = int.tryParse(jerseyStr);
                        }

                        await db
                            .into(db.players)
                            .insert(
                              PlayersCompanion.insert(
                                teamId: widget.teamId,
                                firstName: r['firstName'] ?? '',
                                lastName: r['lastName'] ?? '',
                                isPresent: const drift.Value(
                                  true,
                                ), // Default to true
                                jerseyNumber: drift.Value(jerseyNumber),
                              ),
                            );
                      }
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }
}
