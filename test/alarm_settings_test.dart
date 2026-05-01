import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soccer_assistant_coach/core/providers.dart';

/// Pumps async work through the real zone so the AlarmSettingsNotifier's
/// fire-and-forget `_init()` future can complete. We intentionally avoid
/// `pumpAndSettle` (this is a unit test, not a widget test).
Future<void> _flushAsync() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AlarmSettings model', () {
    test('default values match production expectations', () {
      const s = AlarmSettings();
      expect(s.shiftsEnabled, isTrue);
      expect(s.halftimeEnabled, isTrue);
      expect(s.vibrationEnabled, isTrue);
      expect(s.durationSeconds, 60);
      expect(s.volume, closeTo(0.8, 0.001));
      expect(s.shiftSound, AlarmSoundType.classic);
      expect(s.halftimeSound, AlarmSoundType.gentle);
    });

    test('copyWith only overrides specified fields', () {
      const s = AlarmSettings();
      final modified = s.copyWith(shiftsEnabled: false, durationSeconds: 30);
      expect(modified.shiftsEnabled, isFalse);
      expect(modified.durationSeconds, 30);
      // Untouched fields preserved.
      expect(modified.halftimeEnabled, s.halftimeEnabled);
      expect(modified.vibrationEnabled, s.vibrationEnabled);
      expect(modified.shiftSound, s.shiftSound);
    });

    test('toJson / fromJson is a stable round-trip', () {
      const original = AlarmSettings(
        shiftsEnabled: false,
        halftimeEnabled: true,
        shiftSound: AlarmSoundType.urgent,
        halftimeSound: AlarmSoundType.whistle,
        volume: 0.4,
        durationSeconds: 15,
        vibrationEnabled: false,
      );
      final restored = AlarmSettings.fromJson(original.toJson());
      expect(restored.shiftsEnabled, original.shiftsEnabled);
      expect(restored.halftimeEnabled, original.halftimeEnabled);
      expect(restored.shiftSound, original.shiftSound);
      expect(restored.halftimeSound, original.halftimeSound);
      expect(restored.volume, original.volume);
      expect(restored.durationSeconds, original.durationSeconds);
      expect(restored.vibrationEnabled, original.vibrationEnabled);
    });

    test('fromJson tolerates unknown sound names', () {
      final restored = AlarmSettings.fromJson({
        'shiftSound': 'definitely_not_a_real_sound',
      });
      // Falls back to the default rather than throwing.
      expect(restored.shiftSound, AlarmSoundType.classic);
    });
  });

  group('AlarmSettingsNotifier', () {
    test('updates persist via the provider state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Read once to construct the notifier and trigger _init().
      final notifier = container.read(alarmSettingsProvider.notifier);
      await _flushAsync();

      await notifier.setShiftsEnabled(false);
      await notifier.setDuration(30);
      await notifier.setVibrationEnabled(false);

      final state = container.read(alarmSettingsProvider);
      expect(state.shiftsEnabled, isFalse);
      expect(state.durationSeconds, 30);
      expect(state.vibrationEnabled, isFalse);
    });

    test('persisted settings are restored on a fresh container', () async {
      // First container writes settings.
      final c1 = ProviderContainer();
      addTearDown(c1.dispose);
      final n1 = c1.read(alarmSettingsProvider.notifier);
      await _flushAsync();
      await n1.setHalftimeEnabled(false);
      await n1.setShiftSound(AlarmSoundType.urgent);

      // Second container reads from the same SharedPreferences mock.
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      c2.read(alarmSettingsProvider.notifier);
      await _flushAsync();

      final state = c2.read(alarmSettingsProvider);
      expect(state.halftimeEnabled, isFalse);
      expect(state.shiftSound, AlarmSoundType.urgent);
    });
  });
}
