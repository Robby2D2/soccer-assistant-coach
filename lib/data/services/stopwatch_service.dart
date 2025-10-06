import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final stopwatchProvider = StateNotifierProvider.autoDispose
    .family<StopwatchCtrl, int, int>((_, gameId) => StopwatchCtrl(gameId));

class StopwatchCtrl extends StateNotifier<int> {
  StopwatchCtrl(this.gameId) : super(0) {
    _restore();
  }
  final int gameId;
  Timer? _t;
  DateTime? _startedAt;

  String get _prefKey => 'timer_started_at_$gameId';
  String get _elapsedKey => 'timer_elapsed_$gameId';

  Future<void> _restore() async {
    final p = await SharedPreferences.getInstance();
    final ms = p.getInt(_prefKey);
    if (ms != null) {
      _startedAt = DateTime.fromMillisecondsSinceEpoch(ms);
      final seconds = DateTime.now().difference(_startedAt!).inSeconds;
      state = seconds < 0 ? 0 : seconds;
      _tickFromStart();
      return;
    }

    final elapsed = p.getInt(_elapsedKey);
    if (elapsed != null) {
      state = elapsed;
    }
  }

  Future<void> start() async {
    if (_startedAt != null) return;
    final now = DateTime.now();
    _startedAt = now.subtract(Duration(seconds: state));
    final p = await SharedPreferences.getInstance();
    await p.setInt(_prefKey, _startedAt!.millisecondsSinceEpoch);
    await p.remove(_elapsedKey);
    _tickFromStart();
  }

  void _tickFromStart() {
    _t?.cancel();
    if (_startedAt == null) return;
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      state = DateTime.now().difference(_startedAt!).inSeconds;
    });
  }

  Future<void> pause() async {
    _t?.cancel();
    if (_startedAt != null) {
      state = DateTime.now().difference(_startedAt!).inSeconds;
    }
    _startedAt = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_prefKey);
    await p.setInt(_elapsedKey, state);
  }

  Future<void> reset() async {
    _t?.cancel();
    state = 0;
    _startedAt = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_prefKey);
    await p.remove(_elapsedKey);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }
}
