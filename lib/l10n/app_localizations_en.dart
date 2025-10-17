// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Soccer Assistant Coach';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsVibration => 'Alarm Vibration';

  @override
  String get settingsVibrationDescription =>
      'Vibrate device when shift alarm triggers';

  @override
  String get settingsNotifications => 'Notifications & Alarms';

  @override
  String get permissionNotificationsTitle => 'Allow Notifications';

  @override
  String get permissionNotificationsDescription =>
      'Enable shift alarms and game timers to alert you even when the app is closed.';

  @override
  String get permissionExactAlarmTitle => 'Exact Alarms';

  @override
  String get permissionExactAlarmDescription =>
      'Grant exact alarm permission so shift alarms fire at the precise second (Android 12+).';

  @override
  String get permissionRequestButton => 'Request Permissions';

  @override
  String get permissionGranted => 'Permission Granted';

  @override
  String get permissionDenied => 'Permission Denied';

  @override
  String get vibrationEnabledStatus => 'Vibration enabled';

  @override
  String get vibrationDisabledStatus => 'Vibration disabled';

  @override
  String get stopAlarmAction => 'Stop Alarm';

  @override
  String get alarmDismissed => 'Alarm dismissed';

  @override
  String get alarmDismissedBody => 'Countdown continuing…';
}
