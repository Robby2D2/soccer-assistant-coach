import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize timezone (needed for scheduled notifications)
  tz.initializeTimeZones();
  // Initialize notifications and request permissions
  final notif = NotificationService.instance;
  notif.init();
  notif.requestPermissions();
  runApp(const ProviderScope(child: SoccerApp()));
}
