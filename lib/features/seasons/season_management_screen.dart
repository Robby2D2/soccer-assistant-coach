import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../core/season_provider.dart';
import '../../core/team_theme_manager.dart';

class SeasonManagementScreen extends ConsumerStatefulWidget {
  const SeasonManagementScreen({super.key});

  @override
  ConsumerState<SeasonManagementScreen> createState() =>
      _SeasonManagementScreenState();
}

class _SeasonManagementScreenState
    extends ConsumerState<SeasonManagementScreen> {
  bool _showArchived = false;

  Future<void> _createNewSeason() async {
    final db = ref.read(dbProvider);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateSeasonDialog(db: db),
    );

    if (result != null) {
      try {
        // Show loading dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context).creatingSeason),
                ],
              ),
            ),
          );
        }

        final selectedTeamIds = result['selectedTeamIds'] as List<int>? ?? [];

        if (selectedTeamIds.isEmpty) {
          // Create empty season
          await db.createSeason(
            name: result['name'] as String,
            startDate: result['startDate'] as DateTime,
            endDate: result['endDate'] as DateTime?,
          );
        } else {
          // Create season with selected teams cloned
          await db.cloneSelectedTeamsToSeason(
            newSeasonName: result['name'] as String,
            newStartDate: result['startDate'] as DateTime,
            newEndDate: result['endDate'] as DateTime?,
            teamIds: selectedTeamIds,
          );
        }

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).seasonCreatedSuccessfully,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).errorCreatingSeason(e.toString()),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _cloneSeason(Season season) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CloneSeasonDialog(sourceSeason: season),
    );

    if (result != null) {
      final db = ref.read(dbProvider);
      try {
        // Show loading dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cloning season...'),
                ],
              ),
            ),
          );
        }

        await db.cloneSeason(
          fromSeasonId: season.id,
          newSeasonName: result['name'] as String,
          newStartDate: result['startDate'] as DateTime,
          newEndDate: result['endDate'] as DateTime?,
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Season cloned successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error cloning season: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final seasonsAsync = ref.watch(seasonsProvider(_showArchived));
    final currentSeasonAsync = ref.watch(currentSeasonProvider);

    return TeamScaffold(
      appBar: TeamAppBar(
        titleText: 'Season Management',
        actions: [
          IconButton(
            icon: Icon(_showArchived ? Icons.inventory_2 : Icons.archive),
            tooltip: _showArchived ? 'Hide archived' : 'Show archived',
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Home',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewSeason,
        tooltip: 'Create New Season',
        child: const Icon(Icons.add),
      ),
      body: seasonsAsync.when(
        data: (seasons) {
          if (seasons.isEmpty) {
            return _buildEmptyState();
          }

          return currentSeasonAsync.when(
            data: (currentSeason) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: seasons.length,
              itemBuilder: (context, index) {
                final season = seasons[index];
                final isActive = currentSeason?.id == season.id;
                return _SeasonCard(
                  season: season,
                  isActive: isActive,
                  onActivate: () => _activateSeason(season.id),
                  onArchive: () => _archiveSeason(season.id),
                  onClone: () => _cloneSeason(season),
                  onEdit: () => _editSeason(season),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Icon(
                Icons.calendar_today,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Seasons Yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first season to get started with organizing your teams and games.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activateSeason(int seasonId) async {
    final db = ref.read(dbProvider);
    try {
      await db.setActiveSeason(seasonId);
      // The StreamProvider will automatically update when the database changes
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Season activated!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error activating season: $e')));
      }
    }
  }

  Future<void> _archiveSeason(int seasonId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Season'),
        content: const Text(
          'Are you sure you want to archive this season? You can unarchive it later if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(dbProvider);
      try {
        await db.archiveSeason(seasonId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Season archived!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error archiving season: $e')));
        }
      }
    }
  }

  Future<void> _editSeason(Season season) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EditSeasonDialog(season: season),
    );

    if (result != null) {
      final db = ref.read(dbProvider);
      try {
        await db.updateSeason(
          seasonId: season.id,
          name: result['name'] as String?,
          startDate: result['startDate'] as DateTime?,
          endDate: result['endDate'] as DateTime?,
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Season updated!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating season: $e')));
        }
      }
    }
  }
}

class _SeasonCard extends StatelessWidget {
  final Season season;
  final bool isActive;
  final VoidCallback onActivate;
  final VoidCallback onArchive;
  final VoidCallback onClone;
  final VoidCallback onEdit;

  const _SeasonCard({
    required this.season,
    required this.isActive,
    required this.onActivate,
    required this.onArchive,
    required this.onClone,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isActive ? colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              season.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? colorScheme.onPrimaryContainer
                                        : null,
                                  ),
                            ),
                          ),
                          if (isActive) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                          if (season.isArchived) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.outline,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'ARCHIVED',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: colorScheme.surface,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDateRange(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isActive
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'activate':
                        onActivate();
                        break;
                      case 'edit':
                        onEdit();
                        break;
                      case 'clone':
                        onClone();
                        break;
                      case 'archive':
                        onArchive();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!isActive && !season.isArchived)
                      const PopupMenuItem(
                        value: 'activate',
                        child: ListTile(
                          leading: Icon(Icons.check_circle),
                          title: Text('Activate'),
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clone',
                      child: ListTile(
                        leading: Icon(Icons.copy),
                        title: Text('Clone Season'),
                      ),
                    ),
                    if (!season.isArchived)
                      const PopupMenuItem(
                        value: 'archive',
                        child: ListTile(
                          leading: Icon(Icons.archive),
                          title: Text('Archive'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange() {
    final start = season.startDate;
    final end = season.endDate;

    if (end != null) {
      return '${_formatDate(start)} - ${_formatDate(end)}';
    } else {
      return '${_formatDate(start)} - Ongoing';
    }
  }

  String _formatDate(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

class _CreateSeasonDialog extends StatefulWidget {
  final AppDb db;

  const _CreateSeasonDialog({required this.db});

  @override
  State<_CreateSeasonDialog> createState() => _CreateSeasonDialogState();
}

class _CreateSeasonDialogState extends State<_CreateSeasonDialog> {
  final _nameController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<Team> _availableTeams = [];
  final Set<int> _selectedTeamIds = {};
  bool _isLoadingTeams = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableTeams();
  }

  Future<void> _loadAvailableTeams() async {
    try {
      // Get teams from all seasons to allow cross-season cloning
      final teams = await widget.db.getAllTeams();
      setState(() {
        _availableTeams = teams;
        _isLoadingTeams = false;
      });
    } catch (e) {
      setState(() => _isLoadingTeams = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).createNewSeason),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Season Name',
                hintText: 'e.g., "2024 Spring Season"',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start Date'),
              subtitle: Text(_formatDate(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _startDate = date);
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End Date (Optional)'),
              subtitle: Text(
                _endDate != null ? _formatDate(_endDate!) : 'No end date',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      _endDate ?? _startDate.add(const Duration(days: 180)),
                  firstDate: _startDate,
                  lastDate: DateTime(2030),
                );
                setState(() => _endDate = date);
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Clone Teams (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoadingTeams)
              const Center(child: CircularProgressIndicator())
            else if (_availableTeams.isEmpty)
              const Text('No existing teams to clone')
            else
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    children: _availableTeams.map((team) {
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(team.name),
                        subtitle: FutureBuilder<Season?>(
                          future: widget.db.getSeason(team.seasonId),
                          builder: (context, snapshot) {
                            final season = snapshot.data;
                            return Text(
                              season?.name ?? 'Unknown Season',
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          },
                        ),
                        value: _selectedTeamIds.contains(team.id),
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedTeamIds.add(team.id);
                            } else {
                              _selectedTeamIds.remove(team.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            if (_selectedTeamIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_selectedTeamIds.length} teams selected for cloning',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _nameController.text.isNotEmpty
              ? () => Navigator.of(context).pop({
                  'name': _nameController.text,
                  'startDate': _startDate,
                  'endDate': _endDate,
                  'selectedTeamIds': _selectedTeamIds.toList(),
                })
              : null,
          child: Text(AppLocalizations.of(context).create),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

class _CloneSeasonDialog extends StatefulWidget {
  final Season sourceSeason;

  const _CloneSeasonDialog({required this.sourceSeason});

  @override
  State<_CloneSeasonDialog> createState() => _CloneSeasonDialogState();
}

class _CloneSeasonDialogState extends State<_CloneSeasonDialog> {
  late final TextEditingController _nameController;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: '${widget.sourceSeason.name} (Copy)',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Clone "${widget.sourceSeason.name}"'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will copy all teams, players, and formations from the selected season.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'New Season Name'),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start Date'),
              subtitle: Text(_formatDate(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _startDate = date);
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End Date (Optional)'),
              subtitle: Text(
                _endDate != null ? _formatDate(_endDate!) : 'No end date',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      _endDate ?? _startDate.add(const Duration(days: 180)),
                  firstDate: _startDate,
                  lastDate: DateTime(2030),
                );
                setState(() => _endDate = date);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _nameController.text.isNotEmpty
              ? () => Navigator.of(context).pop({
                  'name': _nameController.text,
                  'startDate': _startDate,
                  'endDate': _endDate,
                })
              : null,
          child: const Text('Clone Season'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

class _EditSeasonDialog extends StatefulWidget {
  final Season season;

  const _EditSeasonDialog({required this.season});

  @override
  State<_EditSeasonDialog> createState() => _EditSeasonDialogState();
}

class _EditSeasonDialogState extends State<_EditSeasonDialog> {
  late final TextEditingController _nameController;
  late DateTime _startDate;
  late DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.season.name);
    _startDate = widget.season.startDate;
    _endDate = widget.season.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Season'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Season Name'),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start Date'),
              subtitle: Text(_formatDate(_startDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _startDate = date);
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End Date (Optional)'),
              subtitle: Text(
                _endDate != null ? _formatDate(_endDate!) : 'No end date',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate:
                      _endDate ?? _startDate.add(const Duration(days: 180)),
                  firstDate: _startDate,
                  lastDate: DateTime(2030),
                );
                setState(() => _endDate = date);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _nameController.text.isNotEmpty
              ? () => Navigator.of(context).pop({
                  'name': _nameController.text,
                  'startDate': _startDate,
                  'endDate': _endDate,
                })
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}
