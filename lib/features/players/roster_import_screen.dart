import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/providers.dart';
import '../../core/team_theme_manager.dart';
import '../../widgets/sideline_header.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/csv.dart';
import '../../utils/roster_diff.dart';

class RosterImportScreen extends ConsumerStatefulWidget {
  final int teamId;
  const RosterImportScreen({super.key, required this.teamId});

  @override
  ConsumerState<RosterImportScreen> createState() => _RosterImportScreenState();
}

class _RosterImportScreenState extends ConsumerState<RosterImportScreen> {
  final _textCtrl = TextEditingController();
  List<Map<String, String>> _rows = [];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _parseCsv(String csv) {
    setState(() => _rows = csvToPlayers(csv));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    final content = String.fromCharCodes(bytes);
    _textCtrl.text = content;
    _parseCsv(content);
  }

  Future<void> _reviewAndImport() async {
    if (_rows.isEmpty) return;
    final db = ref.read(dbProvider);
    final team = await db.getTeam(widget.teamId);
    if (team == null || !mounted) return;
    final existing = await db.getPlayersByTeam(
      widget.teamId,
      seasonId: team.seasonId,
    );
    final diff = diffRoster(existing, _rows);

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(diff: diff),
    );
    if (confirmed != true || !mounted) return;

    for (final row in diff.toAdd) {
      final jersey = int.tryParse(row['jerseyNumber']?.trim() ?? '');
      await db.into(db.players).insert(
        PlayersCompanion.insert(
          teamId: widget.teamId,
          seasonId: team.seasonId,
          firstName: row['firstName'] ?? '',
          lastName: row['lastName'] ?? '',
          jerseyNumber: drift.Value(jersey),
          isPresent: const drift.Value(true),
        ),
      );
    }
    for (final u in diff.toUpdate) {
      final jersey = int.tryParse(u.csvRow['jerseyNumber']?.trim() ?? '');
      await db.updatePlayer(
        id: u.existing.id,
        firstName: u.existing.firstName,
        lastName: u.existing.lastName,
        isPresent: true,
        jerseyNumber: jersey,
        profileImagePath: u.existing.profileImagePath,
      );
    }
    for (final p in diff.toArchive) {
      await db.updatePlayer(
        id: p.id,
        firstName: p.firstName,
        lastName: p.lastName,
        isPresent: false,
        jerseyNumber: p.jerseyNumber,
        profileImagePath: p.profileImagePath,
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return TeamScaffold(
      teamId: widget.teamId,
      header: SidelineScreenHeader(
        teamId: widget.teamId,
        subtitle: loc.importRosterCsv,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: Text(loc.pickCsvFile),
            ),
            const SizedBox(height: 16),
            Text(
              loc.orPasteCsvBelow,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _textCtrl,
                expands: true,
                maxLines: null,
                minLines: null,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: loc.csvHintText,
                ),
                onChanged: _parseCsv,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                loc.previewRows(_rows.length),
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
                      loc.jerseyNumber(
                        r['jerseyNumber']?.isNotEmpty == true
                            ? r['jerseyNumber']!
                            : loc.jerseyNA,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _rows.isEmpty ? null : _reviewAndImport,
              child: Text(loc.reviewAndImport),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final RosterDiff diff;
  const _ConfirmDialog({required this.diff});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.confirmImportTitle),
      content: diff.hasChanges
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (diff.toAdd.isNotEmpty)
                  _ActionRow(
                    icon: Icons.person_add,
                    color: Theme.of(context).colorScheme.primary,
                    label: loc.confirmImportAdd(diff.toAdd.length),
                  ),
                if (diff.toUpdate.isNotEmpty)
                  _ActionRow(
                    icon: Icons.edit,
                    color: Theme.of(context).colorScheme.secondary,
                    label: loc.confirmImportUpdate(diff.toUpdate.length),
                  ),
                if (diff.toArchive.isNotEmpty)
                  _ActionRow(
                    icon: Icons.archive,
                    color: Theme.of(context).colorScheme.error,
                    label: loc.confirmImportArchive(diff.toArchive.length),
                  ),
              ],
            )
          : Text(loc.noChangesDetected),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(loc.cancel),
        ),
        if (diff.hasChanges)
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.import),
          ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _ActionRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
