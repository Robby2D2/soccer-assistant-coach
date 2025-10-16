import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'alert_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Track active shift timers for status bar notifications
  final Map<int, Timer?> _activeShiftTimers = {};
  final Map<int, bool> _shiftAlarmsActive = {};

  /// Handles notification tap/action responses
  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    final actionId = response.actionId;

    // Debug: Print response details
    debugPrint('Notification response: payload=$payload, actionId=$actionId');

    // Handle shift alarm notifications (both tap and action button)
    if (payload?.startsWith('shift_alarm:') == true) {
      // Extract game ID from the payload
      final gameIdStr = payload?.replaceFirst('shift_alarm:', '');
      debugPrint('Extracted gameId from payload: $gameIdStr');

      if (gameIdStr != null) {
        final gameId = int.tryParse(gameIdStr);
        debugPrint('Parsed gameId: $gameId');

        if (gameId != null) {
          debugPrint('Dismissing shift alarm for game $gameId');
          // Dismiss the alarm notification and stop the alert service
          dismissShiftAlarm(gameId);
          // Also stop the alert service
          AlertService.instance.acknowledgeAlert();
        }
      }
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

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

    // Channel for shift countdown notifications (ongoing, no sound)
    const shiftCountdownChannel = AndroidNotificationChannel(
      'shift_countdown',
      'Shift Countdown',
      description: 'Shows remaining time in current shift',
      importance: Importance.low,
      playSound: false,
      showBadge: false,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(shiftCountdownChannel);

    // Channel for shift alarm notifications (high priority, sound)
    const shiftAlarmChannel = AndroidNotificationChannel(
      'shift_alarm',
      'Shift Alarm',
      description: 'Alarm when shift time ends - dismissible from status bar',
      importance: Importance.max,
      playSound: true,
      showBadge: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(shiftAlarmChannel);

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

    // Request exact alarm permission for Android 12+
    await androidImpl?.requestExactAlarmsPermission();

    // iOS
    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImpl?.requestPermissions(alert: true, sound: true, badge: false);
  }

  Future<bool> canScheduleExactAlarms() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await androidImpl?.canScheduleExactNotifications() ?? true;
  }

  /// Request exact alarm permission and return whether it was granted
  Future<bool> requestExactAlarmPermission() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImpl != null) {
      // Check if already granted
      final canSchedule = await androidImpl.canScheduleExactNotifications();
      if (canSchedule == true) {
        return true;
      }

      // Request permission
      await androidImpl.requestExactAlarmsPermission();

      // Check if granted after request
      return await androidImpl.canScheduleExactNotifications() ?? false;
    }

    return true; // iOS or other platforms
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

    try {
      // First try exact scheduling
      await _plugin.zonedSchedule(
        _idForGame(gameId),
        title,
        body,
        tzAt,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'game:$gameId',
      );
    } catch (e) {
      // If exact alarms fail, fall back to inexact
      if (e.toString().contains('exact_alarms_not_permitted')) {
        await _plugin.zonedSchedule(
          _idForGame(gameId),
          title,
          body,
          tzAt,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'game:$gameId',
        );
      } else {
        // Re-throw other errors
        rethrow;
      }
    }
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
      const NotificationDetails(android: android, iOS: ios),
      payload: 'stopwatch:$gameId',
    );
  }

  Future<void> cancelStopwatch(int gameId) async {
    if (!_initialized) await init();
    await _plugin.cancel(_stopwatchNotifId + gameId);
  }

  // --- Shift-Based Countdown & Alarm Notifications ---
  static const int _shiftCountdownNotifId = 77800;
  static const int _shiftAlarmNotifId = 77900;

  /// Starts showing a persistent countdown notification during a shift
  /// This replaces the regular stopwatch notification for shift-based games
  Future<void> startShiftCountdown({
    required int gameId,
    required int shiftLengthSeconds,
    required String matchupTitle,
    int? shiftNumber,
  }) async {
    if (!_initialized) await init();

    // Cancel any existing countdown for this game
    await cancelShiftCountdown(gameId);

    // Start timer to update countdown every second
    _activeShiftTimers[gameId] = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      if (!_activeShiftTimers.containsKey(gameId) ||
          _activeShiftTimers[gameId] != timer) {
        timer.cancel();
        return;
      }

      // Get current elapsed time from stopwatch service to stay in sync
      // We'll pass the current seconds from the game screen instead
      // This timer just ensures the notification stays visible
      // The actual content will be updated via showOrUpdateShiftCountdown
    });
  }

  /// Updates the shift countdown notification with current time
  Future<void> showOrUpdateShiftCountdown({
    required int gameId,
    required int currentSeconds,
    required int shiftLengthSeconds,
    required String matchupTitle,
    int? shiftNumber,
  }) async {
    if (!_initialized) await init();

    final remainingSeconds = shiftLengthSeconds - currentSeconds;
    final isOvertime = remainingSeconds < 0;
    final abs = remainingSeconds.abs();
    final mins = abs ~/ 60;
    final secs = abs % 60;
    final mmss =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final timeText = isOvertime ? '+$mmss over' : '$mmss left';
    final shiftText = shiftNumber == null ? '' : 'Shift #$shiftNumber  ';
    final contentText = '$shiftText$timeText';

    // Check if we should trigger the alarm (when remaining <= 0 and not already alarming)
    if (remainingSeconds <= 0 && !(_shiftAlarmsActive[gameId] ?? false)) {
      await _triggerShiftAlarm(gameId, matchupTitle, shiftNumber);
      return; // Don't show countdown notification when alarm is active
    }

    // Don't show countdown notification if alarm is currently active
    if (_shiftAlarmsActive[gameId] == true) {
      return; // Skip countdown update when alarm is showing
    }

    // Show ongoing countdown notification (silent, low priority)
    const android = AndroidNotificationDetails(
      'shift_countdown',
      'Shift Countdown',
      channelDescription: 'Shows remaining time in current shift',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      onlyAlertOnce: true,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
      colorized: true,
      color: Color.fromARGB(255, 33, 150, 243), // Blue color for countdown
    );

    const ios = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
      interruptionLevel: InterruptionLevel.passive,
      threadIdentifier: 'shift_countdown_thread',
    );

    await _plugin.show(
      _shiftCountdownNotifId + gameId,
      matchupTitle,
      contentText,
      const NotificationDetails(android: android, iOS: ios),
      payload: 'shift_countdown:$gameId',
    );
  }

  /// Triggers the shift alarm notification (dismissible from status bar)
  Future<void> _triggerShiftAlarm(
    int gameId,
    String matchupTitle,
    int? shiftNumber,
  ) async {
    _shiftAlarmsActive[gameId] = true;

    // Cancel the countdown notification
    await _plugin.cancel(_shiftCountdownNotifId + gameId);

    final shiftText = shiftNumber == null ? 'Shift' : 'Shift #$shiftNumber';

    final android = AndroidNotificationDetails(
      'shift_alarm',
      'Shift Alarm',
      channelDescription:
          'Alarm when shift time ends - dismissible from status bar',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      icon: '@mipmap/ic_launcher',
      colorized: true,
      color: const Color.fromARGB(255, 244, 67, 54), // Red color for alarm
      // Make the entire notification tappable to dismiss
      autoCancel: true,
      actions: [
        AndroidNotificationAction(
          'dismiss_$gameId',
          'Dismiss',
          cancelNotification: false, // We'll handle dismissal ourselves
          showsUserInterface: false,
        ),
      ],
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
      threadIdentifier: 'shift_alarm_thread',
    );

    await _plugin.show(
      _shiftAlarmNotifId + gameId,
      '$shiftText Complete!',
      'Time to change lines. Tap to dismiss.',
      NotificationDetails(android: android, iOS: ios),
      payload: 'shift_alarm:$gameId',
    );
  }

  /// Dismisses the shift alarm and returns to countdown mode
  Future<void> dismissShiftAlarm(int gameId) async {
    if (!_initialized) await init();

    _shiftAlarmsActive[gameId] = false;
    await _plugin.cancel(_shiftAlarmNotifId + gameId);

    // The countdown notification will resume automatically when
    // showOrUpdateShiftCountdown is called again from the game screen
  }

  /// Cancels shift countdown and any associated timers
  Future<void> cancelShiftCountdown(int gameId) async {
    if (!_initialized) await init();

    // Cancel timer
    _activeShiftTimers[gameId]?.cancel();
    _activeShiftTimers.remove(gameId);

    // Cancel notifications
    await _plugin.cancel(_shiftCountdownNotifId + gameId);
    await _plugin.cancel(_shiftAlarmNotifId + gameId);

    // Clear alarm state
    _shiftAlarmsActive.remove(gameId);
  }

  /// Checks if a shift alarm is currently active for the game
  bool isShiftAlarmActive(int gameId) {
    return _shiftAlarmsActive[gameId] ?? false;
  }
}
