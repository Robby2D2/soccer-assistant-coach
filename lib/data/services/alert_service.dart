import 'dart:async';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class AlertService {
  AlertService._();
  static final AlertService instance = AlertService._();

  Timer? _alertTimer;
  bool _isAlerting = false;

  /// Triggers a shift change alert with audio and haptic feedback
  /// Continues to alert for [durationSeconds] until acknowledged
  Future<void> triggerShiftChangeAlert({int durationSeconds = 60}) async {
    if (_isAlerting)
      return; // Don't start another alert if one is already active

    _isAlerting = true;

    // Start the alert loop
    await _startAlertLoop(durationSeconds);
  }

  /// Stops any active shift change alert
  Future<void> acknowledgeAlert() async {
    _isAlerting = false;
    _alertTimer?.cancel();
    _alertTimer = null;
  }

  /// Internal method to handle the alert loop
  Future<void> _startAlertLoop(int totalDurationSeconds) async {
    const alertIntervalSeconds = 5; // Play alert every 5 seconds
    int elapsedSeconds = 0;

    // Play initial alert
    await _playAlertSound();
    await _playHapticFeedback();

    // Set up timer to repeat alerts
    _alertTimer = Timer.periodic(
      const Duration(seconds: alertIntervalSeconds),
      (timer) async {
        elapsedSeconds += alertIntervalSeconds;

        if (!_isAlerting || elapsedSeconds >= totalDurationSeconds) {
          timer.cancel();
          _alertTimer = null;
          _isAlerting = false;
          return;
        }

        // Play alert sound and haptic feedback
        await _playAlertSound();
        await _playHapticFeedback();
      },
    );
  }

  /// Plays the alert sound - uses system alarm sound
  Future<void> _playAlertSound() async {
    try {
      // Use system alert sound for now - this is typically louder than click
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      // Fallback to click if alert sound isn't available
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {
        // If even system sound fails, ignore
      }
    }
  }

  /// Plays haptic feedback with strong vibration
  Future<void> _playHapticFeedback() async {
    try {
      // Use the vibration package for more control
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // Create a vibration pattern: [wait, vibrate, wait, vibrate, wait, vibrate]
        await Vibration.vibrate(
          pattern: [0, 500, 200, 500, 200, 500], // Strong triple vibration
          intensities: [0, 255, 0, 255, 0, 255], // Max intensity when vibrating
        );
      }
    } catch (_) {
      // Fallback to Flutter's haptic feedback
      try {
        await HapticFeedback.heavyImpact();
        // Wait a bit then do another
        await Future.delayed(const Duration(milliseconds: 200));
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 200));
        await HapticFeedback.heavyImpact();
      } catch (_) {
        // Ignore if haptic feedback isn't available
      }
    }
  }

  /// Simple one-time alert for other notifications (less intrusive)
  Future<void> playSimpleAlert() async {
    try {
      await SystemSound.play(SystemSoundType.click);
      await HapticFeedback.lightImpact();
    } catch (_) {
      // Ignore if not available
    }
  }

  bool get isAlerting => _isAlerting;

  void dispose() {
    _alertTimer?.cancel();
  }
}
