import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/sound_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final alarmSettings = ref.watch(alarmSettingsProvider);
    final alarmNotifier = ref.read(alarmSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(loc.settingsTitle)),
      body: ListView(
        children: [
          // Current Configuration Summary
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Current Configuration',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ConfigSummaryRow(
                  'Shift Alarms',
                  alarmSettings.shiftsEnabled ? 'Enabled' : 'Disabled',
                  alarmSettings.shiftsEnabled,
                ),
                _ConfigSummaryRow(
                  'Halftime Alarms',
                  alarmSettings.halftimeEnabled ? 'Enabled' : 'Disabled',
                  alarmSettings.halftimeEnabled,
                ),
                _ConfigSummaryRow(
                  'Vibration',
                  alarmSettings.vibrationEnabled ? 'On' : 'Off',
                  alarmSettings.vibrationEnabled,
                ),
                _ConfigSummaryRow(
                  'Duration',
                  '${alarmSettings.durationSeconds} seconds',
                  true,
                ),
                _ConfigSummaryRow(
                  'Volume',
                  '${(alarmSettings.volume * 100).round()}%',
                  true,
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final selectedLanguage = ref.watch(languagePrefProvider);
                    final language = SupportedLanguage.values.firstWhere(
                      (lang) => lang.code == selectedLanguage,
                      orElse: () => SupportedLanguage.english,
                    );
                    return _ConfigSummaryRow(
                      'Language',
                      '${language.flag} ${language.displayName}',
                      true,
                    );
                  },
                ),
              ],
            ),
          ),

          _SectionHeader(title: loc.settingsNotifications),
          _PermissionTile(),

          const Divider(height: 32),
          _SectionHeader(title: loc.alarmCustomization),

          // Enable/Disable Shift Alarms
          SwitchListTile.adaptive(
            title: Text(loc.shiftAlarmsEnabled),
            subtitle: Text(loc.shiftAlarmsDescription),
            value: alarmSettings.shiftsEnabled,
            onChanged: (v) => alarmNotifier.setShiftsEnabled(v),
            secondary: Icon(
              alarmSettings.shiftsEnabled ? Icons.alarm : Icons.alarm_off,
            ),
          ),

          // Enable/Disable Halftime Alarms
          SwitchListTile.adaptive(
            title: Text(loc.halftimeAlarmsEnabled),
            subtitle: Text(loc.halftimeAlarmsDescription),
            value: alarmSettings.halftimeEnabled,
            onChanged: (v) => alarmNotifier.setHalftimeEnabled(v),
            secondary: Icon(
              alarmSettings.halftimeEnabled ? Icons.timer : Icons.timer_off,
            ),
          ),

          const Divider(height: 32),
          _SectionHeader(title: loc.alarmSounds),

          // Shift End Sound Selection
          ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(loc.shiftAlarmSound),
            subtitle: Text(alarmSettings.shiftSound.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSoundPicker(
              context,
              loc.shiftAlarmSound,
              alarmSettings.shiftSound,
              (sound) => alarmNotifier.setShiftSound(sound),
            ),
          ),

          // Halftime Sound Selection
          ListTile(
            leading: const Icon(Icons.audiotrack),
            title: Text(loc.halftimeAlarmSound),
            subtitle: Text(alarmSettings.halftimeSound.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSoundPicker(
              context,
              loc.halftimeAlarmSound,
              alarmSettings.halftimeSound,
              (sound) => alarmNotifier.setHalftimeSound(sound),
            ),
          ),

          // Volume Control
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: Text(loc.alarmVolume),
            subtitle: Slider(
              value: alarmSettings.volume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: '${(alarmSettings.volume * 100).round()}%',
              onChanged: (v) => alarmNotifier.setVolume(v),
            ),
          ),

          // Duration Control
          ListTile(
            leading: const Icon(Icons.timer),
            title: Text(loc.alarmDuration),
            subtitle: Text(loc.alarmDurationDescription),
            trailing: DropdownButton<int>(
              value: alarmSettings.durationSeconds,
              items: [15, 30, 60, 90, 120].map((seconds) {
                return DropdownMenuItem(
                  value: seconds,
                  child: Text('$seconds ${loc.seconds}'),
                );
              }).toList(),
              onChanged: (duration) {
                if (duration != null) {
                  alarmNotifier.setDuration(duration);
                }
              },
            ),
          ),

          const Divider(height: 32),
          _SectionHeader(title: loc.settingsVibration),

          // Vibration Setting
          SwitchListTile.adaptive(
            title: Text(loc.settingsVibration),
            subtitle: Text(loc.settingsVibrationDescription),
            value: alarmSettings.vibrationEnabled,
            onChanged: (v) => alarmNotifier.setVibrationEnabled(v),
            secondary: Icon(
              alarmSettings.vibrationEnabled
                  ? Icons.vibration
                  : Icons.do_not_disturb,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              alarmSettings.vibrationEnabled
                  ? loc.vibrationEnabledStatus
                  : loc.vibrationDisabledStatus,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: alarmSettings.vibrationEnabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const Divider(height: 32),
          _SectionHeader(title: loc.language),

          // Language Selection
          Consumer(
            builder: (context, ref, child) {
              final selectedLanguage = ref.watch(languagePrefProvider);
              final languageNotifier = ref.read(languagePrefProvider.notifier);

              return ListTile(
                leading: const Icon(Icons.language),
                title: Text(loc.language),
                subtitle: Text(loc.languageDescription),
                trailing: DropdownButton<String>(
                  value: selectedLanguage,
                  underline: Container(),
                  items: SupportedLanguage.values.map((language) {
                    return DropdownMenuItem(
                      value: language.code,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(language.flag),
                          const SizedBox(width: 8),
                          Text(language.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (languageCode) {
                    if (languageCode != null) {
                      languageNotifier.setLanguage(languageCode);
                      final language = SupportedLanguage.values.firstWhere(
                        (lang) => lang.code == languageCode,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Language changed to ${language.displayName}',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),

          const Divider(height: 32),

          // Reset to Defaults
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.orange),
            title: const Text('Reset to Defaults'),
            subtitle: const Text(
              'Restore all alarm settings to their original values',
            ),
            onTap: () => _showResetDialog(context, alarmNotifier),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showSoundPicker(
    BuildContext context,
    String title,
    AlarmSoundType currentSound,
    Function(AlarmSoundType) onChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => _SoundPickerDialog(
        title: title,
        currentSound: currentSound,
        onChanged: onChanged,
      ),
    );
  }

  void _showResetDialog(BuildContext context, AlarmSettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all alarm settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () {
              notifier.updateSettings(const AlarmSettings());
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _PermissionTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PermissionTile> createState() => _PermissionTileState();
}

class _PermissionTileState extends ConsumerState<_PermissionTile> {
  bool _checking = false;
  bool _exactAllowed = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _checking = true);
    final allowed = await NotificationService.instance.canScheduleExactAlarms();
    setState(() {
      _exactAllowed = allowed;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ListTile(
      leading: const Icon(Icons.notifications_active),
      title: Text(loc.permissionNotificationsTitle),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.permissionNotificationsDescription),
          const SizedBox(height: 8),
          Text(
            loc.permissionExactAlarmTitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(loc.permissionExactAlarmDescription),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _checking
                    ? null
                    : () async {
                        setState(() => _checking = true);
                        await NotificationService.instance.requestPermissions();
                        final grantedExact = await NotificationService.instance
                            .requestExactAlarmPermission();
                        setState(() {
                          _exactAllowed = grantedExact;
                          _checking = false;
                        });
                      },
                icon: const Icon(Icons.lock_open),
                label: Text(loc.permissionRequestButton),
              ),
              const SizedBox(width: 12),
              if (_checking)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  _exactAllowed ? Icons.check_circle : Icons.error,
                  color: _exactAllowed
                      ? Colors.green
                      : Theme.of(context).colorScheme.error,
                ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}

class _SoundPickerDialog extends StatelessWidget {
  final String title;
  final AlarmSoundType currentSound;
  final Function(AlarmSoundType) onChanged;

  const _SoundPickerDialog({
    required this.title,
    required this.currentSound,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: AlarmSoundType.values.length,
          itemBuilder: (context, index) {
            final sound = AlarmSoundType.values[index];
            final isSelected = sound == currentSound;

            return ListTile(
              leading: Icon(
                _getSoundIcon(sound),
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(
                sound.displayName,
                style: isSelected
                    ? TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
              subtitle: Text(SoundService.instance.getSoundDescription(sound)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    tooltip: loc.previewSound,
                    onPressed: () => _previewSound(sound),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              onTap: () {
                onChanged(sound);
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }

  IconData _getSoundIcon(AlarmSoundType sound) {
    switch (sound) {
      case AlarmSoundType.none:
        return Icons.volume_off;
      case AlarmSoundType.system:
        return Icons.notifications;
      case AlarmSoundType.classic:
        return Icons.alarm;
      case AlarmSoundType.gentle:
        return Icons.music_note;
      case AlarmSoundType.urgent:
        return Icons.error;
      case AlarmSoundType.whistle:
        return Icons.sports_soccer;
    }
  }

  void _previewSound(AlarmSoundType sound) {
    SoundService.instance.previewSound(sound);
  }
}

class _ConfigSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isEnabled;

  const _ConfigSummaryRow(this.label, this.value, this.isEnabled);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
