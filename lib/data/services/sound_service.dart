import 'package:flutter/services.dart';
import '../../core/providers.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  /// Plays a preview of the specified alarm sound type
  Future<void> previewSound(AlarmSoundType soundType) async {
    switch (soundType) {
      case AlarmSoundType.none:
        // No sound, just haptic feedback
        await HapticFeedback.lightImpact();
        break;
      case AlarmSoundType.system:
        await SystemSound.play(SystemSoundType.alert);
        break;
      case AlarmSoundType.classic:
        await SystemSound.play(SystemSoundType.alert);
        await HapticFeedback.mediumImpact();
        break;
      case AlarmSoundType.gentle:
        await SystemSound.play(SystemSoundType.click);
        break;
      case AlarmSoundType.urgent:
        await SystemSound.play(SystemSoundType.alert);
        await HapticFeedback.heavyImpact();
        break;
      case AlarmSoundType.whistle:
        // Use click for now - could be replaced with actual whistle sound
        await SystemSound.play(SystemSoundType.click);
        await HapticFeedback.selectionClick();
        break;
    }
  }

  /// Gets a description of what this sound type will do
  String getSoundDescription(AlarmSoundType soundType) {
    switch (soundType) {
      case AlarmSoundType.none:
        return 'Silent - no sound, only vibration (if enabled)';
      case AlarmSoundType.system:
        return 'Uses your device\'s default notification sound';
      case AlarmSoundType.classic:
        return 'Traditional alarm sound with strong vibration';
      case AlarmSoundType.gentle:
        return 'Soft notification tone for quieter environments';
      case AlarmSoundType.urgent:
        return 'High priority alert with intense vibration';
      case AlarmSoundType.whistle:
        return 'Coach whistle sound - perfect for sports';
    }
  }
}
