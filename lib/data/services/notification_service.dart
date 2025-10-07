import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(initSettings);

    // Create default Android channel for shift alerts
    const androidChannel = AndroidNotificationChannel(
      'shift_alerts',
      'Shift Alerts',
      description: 'Notifications when a shift ends',
      importance: Importance.max,
      playSound: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    // Channel for ongoing stopwatch
    const stopwatchChannel = AndroidNotificationChannel(
      'stopwatch_running',
      'Stopwatch',
      description: 'Ongoing when game stopwatch is running',
      importance: Importance.low,
      playSound: false,
      showBadge: false,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(stopwatchChannel);

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    // Android 13+
    // Android 13+ permission handled via requestNotificationsPermission
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
    // iOS
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImpl?.requestPermissions(alert: true, sound: true, badge: false);
  }

  int _idForGame(int gameId) => gameId; // stable id per game

  Future<void> scheduleShiftEnd({
    required int gameId,
    required DateTime at,
    String title = 'Shift over',
    String body = 'Time to change lines',
  }) async {
    if (!_initialized) await init();
    // Ensure target time is in the future (plugin throws if not)
    final now = DateTime.now();
    if (!at.isAfter(now)) {
      // Nudge at least 1 second into future to avoid ArgumentError
      at = now.add(const Duration(seconds: 1));
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'shift_alerts',
        'Shift Alerts',
        channelDescription: 'Notifications when a shift ends',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
    // Ensure timezone initialized upstream (documented requirement)
    final tzAt = tz.TZDateTime.from(at, tz.local);
    await _plugin.zonedSchedule(
      _idForGame(gameId),
      title,
      body,
      tzAt,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'game:$gameId',
    );
  }

  Future<void> cancelShiftEnd(int gameId) async {
    if (!_initialized) await init();
    await _plugin.cancel(_idForGame(gameId));
  }

  // --- Ongoing Stopwatch Notification ---
  static const int _stopwatchNotifId = 77700; // Arbitrary stable id

  Future<void> showOrUpdateStopwatch({
    required int gameId,
    required int remainingSeconds,
    required String matchupTitle, // e.g. "Team A vs Team B"
    int? shiftNumber,
  }) async {
    if (!_initialized) await init();
    final isOver = remainingSeconds < 0;
    final abs = remainingSeconds.abs();
    final mins = abs ~/ 60;
    final secs = abs % 60;
    final mmss =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    final timePart = isOver ? '+$mmss over' : '$mmss left';
    final shiftPart = shiftNumber == null ? '' : 'Shift #$shiftNumber  ';
    final text = '$shiftPart$timePart';
    const android = AndroidNotificationDetails(
      'stopwatch_running',
      'Stopwatch',
      channelDescription: 'Ongoing when game stopwatch is running',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      onlyAlertOnce: true,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
    );
    const ios = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
      interruptionLevel: InterruptionLevel.passive,
      threadIdentifier: 'stopwatch_thread',
    );
    await _plugin.show(
      _stopwatchNotifId + gameId,
      matchupTitle,
      text,
      NotificationDetails(android: android, iOS: ios),
      payload: 'stopwatch:$gameId',
    );
  }

  Future<void> cancelStopwatch(int gameId) async {
    if (!_initialized) await init();
    await _plugin.cancel(_stopwatchNotifId + gameId);
  }
}
