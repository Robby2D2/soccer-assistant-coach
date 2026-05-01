import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soccer_assistant_coach/data/services/stopwatch_service.dart';

// Note: `start()`, `pause()` and `reset()` all call
// `NotificationService.cancelStopwatch`, which requires the platform-side
// `FlutterLocalNotificationsPlatform.instance` to be initialized — that
// only happens on a real device. Those code paths are exercised by the
// Patrol E2E suite (`integration_test/shift_alarm_journey_test.dart`); the
// tests below cover everything that doesn't reach the notification plugin.

Future<void> _flushAsync() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Spins up a [ProviderContainer], opens the stopwatch provider for [gameId],
/// and keeps a listener alive so the `autoDispose` family doesn't release
/// the provider between calls. Callers receive the controller and a `close`
/// hook that tears everything down deterministically.
Future<({StopwatchCtrl ctrl, ProviderContainer container, void Function() close})>
    _openStopwatch(int gameId) async {
  final container = ProviderContainer();
  final sub = container.listen<int>(stopwatchProvider(gameId), (_, _) {});
  // Wait for the microtask-scheduled `_restore` inside `init()` to settle so
  // it doesn't race with the test's first `state =` assignment.
  await _flushAsync();
  final ctrl = container.read(stopwatchProvider(gameId).notifier);
  return (
    ctrl: ctrl,
    container: container,
    close: () {
      sub.close();
      container.dispose();
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('initial state is 0 elapsed seconds', () async {
    final h = await _openStopwatch(42);
    expect(h.container.read(stopwatchProvider(42)), 0);
    h.close();
  });

  test('setMeta persists team / opponent / shift length / shift number',
      () async {
    final h = await _openStopwatch(7);
    await h.ctrl.setMeta(
      teamName: 'Lions',
      opponent: 'Tigers',
      shiftLengthSeconds: 90,
      shiftNumber: 3,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('timer_meta_7'), 'Lions|Tigers|90|3');
    h.close();
  });

  test('a fresh container restores meta from SharedPreferences', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timer_meta_99', 'Sharks|Whales|120|2');
    await prefs.setInt('timer_elapsed_99', 17);

    final h = await _openStopwatch(99);
    expect(h.container.read(stopwatchProvider(99)), 17);
    h.close();
  });
}
