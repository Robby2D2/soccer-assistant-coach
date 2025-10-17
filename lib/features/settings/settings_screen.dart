import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../data/services/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final vibrationEnabled = ref.watch(vibrationPrefProvider);
    final vibrationNotifier = ref.read(vibrationPrefProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(loc.settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(title: loc.settingsNotifications),
          _PermissionTile(),
          const Divider(height: 32),
          _SectionHeader(title: loc.settingsVibration),
          SwitchListTile.adaptive(
            title: Text(loc.settingsVibration),
            subtitle: Text(loc.settingsVibrationDescription),
            value: vibrationEnabled,
            onChanged: (v) => vibrationNotifier.setEnabled(v),
            secondary: Icon(
              vibrationEnabled ? Icons.vibration : Icons.do_not_disturb,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              vibrationEnabled
                  ? loc.vibrationEnabledStatus
                  : loc.vibrationDisabledStatus,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: vibrationEnabled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
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
