import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soccer_assistant_coach/data/services/alert_service.dart';

/// Encodes [params] as the same query-string format that
/// `AlarmSettingsNotifier.updateSettings` uses, so we can seed a settings
/// blob without going through the notifier.
String _settingsBlob(Map<String, String> params) {
  return params.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final svc = AlertService.instance;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    // Always cancel any in-flight alert so timers don't leak between tests.
    await svc.acknowledgeAlert();
  });

  group('AlertService.triggerShiftChangeAlert', () {
    test('does nothing when shift alarms are disabled', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'alarm_settings',
        _settingsBlob({'shiftsEnabled': 'false', 'durationSeconds': '60'}),
      );

      await svc.triggerShiftChangeAlert(gameId: 1);

      expect(svc.isAlerting, isFalse);
    });

    test('starts alerting when shift alarms are enabled', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'alarm_settings',
        _settingsBlob({'shiftsEnabled': 'true', 'durationSeconds': '5'}),
      );

      await svc.triggerShiftChangeAlert(gameId: 1, durationSeconds: 5);

      expect(svc.isAlerting, isTrue);
    });

    test('acknowledgeAlert stops an active alert', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'alarm_settings',
        _settingsBlob({'shiftsEnabled': 'true', 'durationSeconds': '60'}),
      );
      await svc.triggerShiftChangeAlert(gameId: 1);
      expect(svc.isAlerting, isTrue);

      await svc.acknowledgeAlert();

      expect(svc.isAlerting, isFalse);
    });

    test('a second trigger while alerting is a no-op', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'alarm_settings',
        _settingsBlob({'shiftsEnabled': 'true', 'durationSeconds': '60'}),
      );
      await svc.triggerShiftChangeAlert(gameId: 1);
      // Should not throw or restart.
      await svc.triggerShiftChangeAlert(gameId: 2);

      expect(svc.isAlerting, isTrue);
    });
  });

  group('AlertService.triggerHalftimeAlert', () {
    test('does nothing when halftime alarms are disabled', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'alarm_settings',
        _settingsBlob({'halftimeEnabled': 'false', 'durationSeconds': '60'}),
      );

      await svc.triggerHalftimeAlert(gameId: 1);

      expect(svc.isAlerting, isFalse);
    });

    test('starts alerting when halftime alarms are enabled', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'alarm_settings',
        _settingsBlob({'halftimeEnabled': 'true', 'durationSeconds': '60'}),
      );

      await svc.triggerHalftimeAlert(gameId: 1);

      expect(svc.isAlerting, isTrue);
    });
  });
}
