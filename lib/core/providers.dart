import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

export '../data/db/database.dart';

final dbProvider = Provider<AppDb>((_) => AppDb());

// Vibration preference (default true). Uses Riverpod Notifier API (v3)
final vibrationPrefProvider = NotifierProvider<VibrationPrefNotifier, bool>(() {
  return VibrationPrefNotifier();
});

class VibrationPrefNotifier extends Notifier<bool> {
  static const _key = 'alarm_vibration_enabled';
  SharedPreferences? _prefs;

  @override
  bool build() {
    // Load asynchronously; default true until loaded
    _init();
    return true;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final value = _prefs!.getBool(_key) ?? true;
    state = value;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_key, enabled);
  }
}
