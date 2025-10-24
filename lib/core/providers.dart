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

// Language preference provider
final languagePrefProvider = NotifierProvider<LanguagePrefNotifier, String>(() {
  return LanguagePrefNotifier();
});

class LanguagePrefNotifier extends Notifier<String> {
  static const _key = 'selected_language';
  SharedPreferences? _prefs;

  @override
  String build() {
    // Load asynchronously; default to 'en' until loaded
    _init();
    return 'en';
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final value = _prefs!.getString(_key) ?? 'en';
    state = value;
  }

  Future<void> setLanguage(String languageCode) async {
    state = languageCode;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_key, languageCode);
  }
}

// Available languages
enum SupportedLanguage {
  english('en', 'English', '🇺🇸'),
  spanish('es', 'Español', '🇪🇸'),
  french('fr', 'Français', '🇫🇷');

  const SupportedLanguage(this.code, this.displayName, this.flag);
  final String code;
  final String displayName;
  final String flag;
}

// Alarm settings configuration
class AlarmSettings {
  final bool shiftsEnabled;
  final bool halftimeEnabled;
  final AlarmSoundType shiftSound;
  final AlarmSoundType halftimeSound;
  final double volume;
  final int durationSeconds;
  final bool vibrationEnabled;

  const AlarmSettings({
    this.shiftsEnabled = true,
    this.halftimeEnabled = true,
    this.shiftSound = AlarmSoundType.classic,
    this.halftimeSound = AlarmSoundType.gentle,
    this.volume = 0.8,
    this.durationSeconds = 60,
    this.vibrationEnabled = true,
  });

  AlarmSettings copyWith({
    bool? shiftsEnabled,
    bool? halftimeEnabled,
    AlarmSoundType? shiftSound,
    AlarmSoundType? halftimeSound,
    double? volume,
    int? durationSeconds,
    bool? vibrationEnabled,
  }) {
    return AlarmSettings(
      shiftsEnabled: shiftsEnabled ?? this.shiftsEnabled,
      halftimeEnabled: halftimeEnabled ?? this.halftimeEnabled,
      shiftSound: shiftSound ?? this.shiftSound,
      halftimeSound: halftimeSound ?? this.halftimeSound,
      volume: volume ?? this.volume,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shiftsEnabled': shiftsEnabled,
      'halftimeEnabled': halftimeEnabled,
      'shiftSound': shiftSound.name,
      'halftimeSound': halftimeSound.name,
      'volume': volume,
      'durationSeconds': durationSeconds,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  factory AlarmSettings.fromJson(Map<String, dynamic> json) {
    return AlarmSettings(
      shiftsEnabled: json['shiftsEnabled'] ?? true,
      halftimeEnabled: json['halftimeEnabled'] ?? true,
      shiftSound: AlarmSoundType.values.firstWhere(
        (e) => e.name == json['shiftSound'],
        orElse: () => AlarmSoundType.classic,
      ),
      halftimeSound: AlarmSoundType.values.firstWhere(
        (e) => e.name == json['halftimeSound'],
        orElse: () => AlarmSoundType.gentle,
      ),
      volume: (json['volume'] ?? 0.8).toDouble(),
      durationSeconds: json['durationSeconds'] ?? 60,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
    );
  }
}

enum AlarmSoundType {
  none('None', 'No sound'),
  system('System', 'System alert sound'),
  classic('Classic', 'Traditional alarm'),
  gentle('Gentle', 'Soft notification tone'),
  urgent('Urgent', 'High priority alert'),
  whistle('Whistle', 'Coach whistle sound');

  const AlarmSoundType(this.displayName, this.description);
  final String displayName;
  final String description;
}

// Comprehensive alarm settings provider
final alarmSettingsProvider =
    NotifierProvider<AlarmSettingsNotifier, AlarmSettings>(() {
      return AlarmSettingsNotifier();
    });

class AlarmSettingsNotifier extends Notifier<AlarmSettings> {
  static const _key = 'alarm_settings';
  SharedPreferences? _prefs;

  @override
  AlarmSettings build() {
    _init();
    return const AlarmSettings();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final jsonString = _prefs!.getString(_key);
    if (jsonString != null) {
      try {
        final json = Map<String, dynamic>.from(
          // Simple JSON parsing for our use case
          Uri.splitQueryString(jsonString),
        );
        // Convert string values back to appropriate types
        final parsedData = <String, dynamic>{};
        json.forEach((key, value) {
          switch (key) {
            case 'shiftsEnabled':
            case 'halftimeEnabled':
            case 'vibrationEnabled':
              parsedData[key] = value.toLowerCase() == 'true';
              break;
            case 'volume':
              parsedData[key] = double.tryParse(value) ?? 0.8;
              break;
            case 'durationSeconds':
              parsedData[key] = int.tryParse(value) ?? 60;
              break;
            default:
              parsedData[key] = value;
          }
        });
        state = AlarmSettings.fromJson(parsedData);
      } catch (e) {
        // If parsing fails, use defaults
        state = const AlarmSettings();
      }
    } else {
      // Migrate from old vibration setting if it exists
      final oldVibrationSetting = _prefs!.getBool('alarm_vibration_enabled');
      if (oldVibrationSetting != null) {
        state = AlarmSettings(vibrationEnabled: oldVibrationSetting);
        // Save the migrated settings
        await updateSettings(state);
      }
    }
  }

  Future<void> updateSettings(AlarmSettings settings) async {
    state = settings;
    _prefs ??= await SharedPreferences.getInstance();

    // Simple serialization approach
    final data = settings.toJson();
    final queryParams = data.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    await _prefs!.setString(_key, queryParams);
  }

  Future<void> setShiftsEnabled(bool enabled) async {
    await updateSettings(state.copyWith(shiftsEnabled: enabled));
  }

  Future<void> setHalftimeEnabled(bool enabled) async {
    await updateSettings(state.copyWith(halftimeEnabled: enabled));
  }

  Future<void> setShiftSound(AlarmSoundType sound) async {
    await updateSettings(state.copyWith(shiftSound: sound));
  }

  Future<void> setHalftimeSound(AlarmSoundType sound) async {
    await updateSettings(state.copyWith(halftimeSound: sound));
  }

  Future<void> setVolume(double volume) async {
    await updateSettings(state.copyWith(volume: volume));
  }

  Future<void> setDuration(int seconds) async {
    await updateSettings(state.copyWith(durationSeconds: seconds));
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    await updateSettings(state.copyWith(vibrationEnabled: enabled));
  }
}
