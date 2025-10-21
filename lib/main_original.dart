import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI to hide navigation buttons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Hide system navigation bar (Android buttons) - they can be revealed by swiping up
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize timezone (needed for scheduled notifications)
  tz.initializeTimeZones();
  // Initialize notifications and request permissions
  final notif = NotificationService.instance;
  notif.init();
  notif.requestPermissions();
  runApp(const ProviderScope(child: SoccerApp()));
}
