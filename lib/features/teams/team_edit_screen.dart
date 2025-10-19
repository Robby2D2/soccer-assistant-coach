import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/team_theme_manager.dart';
import '../../widgets/team_header.dart';
import '../../widgets/team_logo_widget.dart';
import '../../widgets/team_color_picker.dart';
import '../../utils/team_image_picker.dart';

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
  String? _logoImagePath;
  List<Color> _teamColors = [];

  @override
  void initState() {
    super.initState();
    final db = ref.read(dbProvider);
    db.getTeam(widget.teamId).then((team) {
      if (!mounted || team == null) return;
      debugPrint('Loaded team: ${team.name}, logo: ${team.logoImagePath}');
      setState(() {
        _name.text = team.name;
        _teamMode = team.teamMode;
        _logoImagePath = team.logoImagePath;
        debugPrint('Set _logoImagePath to: $_logoImagePath');
        _teamColors = ColorHelper.hexListToColors([
          team.primaryColor1,
          team.primaryColor2,
          team.primaryColor3,
        ]);
        // Ensure we have 3 colors
        while (_teamColors.length < 3) {
          _teamColors.add(Colors.grey);
        }
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

  Future<void> _pickTeamLogo() async {
    final logoPath = await TeamImagePicker.pickTeamLogo(context);
    debugPrint('Team logo picked: $logoPath');
    if (logoPath != null) {
      setState(() {
        _logoImagePath = logoPath;
      });
      debugPrint('Team logo path set to: $_logoImagePath');
    }
  }

  Future<void> _removeTeamLogo() async {
    if (_logoImagePath != null) {
      await TeamImagePicker.deleteTeamLogo(_logoImagePath);
      setState(() {
        _logoImagePath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(dbProvider);
    return TeamScaffold(
      teamId: widget.teamId,
      appBar: const TeamAppBar(titleText: 'Edit Team'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final name = _name.text.trim();
          if (name.isEmpty) return;

          await db.updateTeamName(widget.teamId, name);
          await db.setTeamMode(widget.teamId, _teamMode);

          // Save team customization
          debugPrint('Saving team logo: $_logoImagePath');
          await db.updateTeamLogo(widget.teamId, _logoImagePath);
          final hexColors = ColorHelper.colorsToHexList(_teamColors);
          debugPrint('Saving team colors: $hexColors');
          await db.updateTeamColors(
            widget.teamId,
            color1: hexColors.isNotEmpty ? hexColors[0] : null,
            color2: hexColors.length > 1 ? hexColors[1] : null,
            color3: hexColors.length > 2 ? hexColors[2] : null,
          );

          if (_teamMode == 'shift') {
            final mins = int.tryParse(_shiftMinutes.text.trim());
            if (mins != null && mins > 0) {
              await db.setTeamShiftLengthSeconds(widget.teamId, mins * 60);
            }
          } else {
            final mins = int.tryParse(_halfMinutes.text.trim());
            if (mins != null && mins > 0) {
              await db.setTeamHalfDurationSeconds(widget.teamId, mins * 60);
            }
          }

          if (!context.mounted) return;
          Navigator.pop(context);
        },
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TeamBrandedHeader(
                teamId: widget.teamId,
                title: _name.text.isEmpty ? 'Edit Team' : _name.text,
                subtitle: 'Customize appearance & settings',
                padding: const EdgeInsets.all(20),
              ),
            ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Team name'),
            ),
            const SizedBox(height: 24),

            // Team Customization Section
            Text(
              'Team Appearance',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Team Logo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Logo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        EditableTeamLogoWidget(
                          logoPath: _logoImagePath,
                          onEdit: _pickTeamLogo,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Tap to change team logo'),
                              const SizedBox(height: 8),
                              if (_logoImagePath != null)
                                TextButton.icon(
                                  onPressed: _removeTeamLogo,
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text('Remove Logo'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Team Colors
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: TeamColorPicker(
                  initialColors: _teamColors,
                  onColorsChanged: (colors) {
                    setState(() {
                      _teamColors = colors;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

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
          ],
        ),
      ),
    );
  }
}
