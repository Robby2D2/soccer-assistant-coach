import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

final stopwatchProvider = StateNotifierProvider.autoDispose
    .family<StopwatchCtrl, int, int>((_, gameId) => StopwatchCtrl(gameId));

class StopwatchCtrl extends StateNotifier<int> {
  StopwatchCtrl(this.gameId) : super(0) {
    _restore();
  }
  final int gameId;
  Timer? _t;
  DateTime? _startedAt;
  int _shiftLengthSeconds = 300;
  String _teamName = '';
  String _opponent = '';
  int? _shiftNumber;
  int _lastNotifiedSecond = -1;
  bool _sentZeroBoundary = false;

  String get _prefKey => 'timer_started_at_$gameId';
  String get _elapsedKey => 'timer_elapsed_$gameId';
  String get _metaKey =>
      'timer_meta_$gameId'; // stores team|opponent|shiftLength

  Future<void> setMeta({
    required String teamName,
    required String opponent,
    required int shiftLengthSeconds,
    int? shiftNumber,
  }) async {
    _teamName = teamName;
    _opponent = opponent;
    _shiftLengthSeconds = shiftLengthSeconds;
    _shiftNumber = shiftNumber;
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _metaKey,
      '${_teamName.replaceAll('|', '/')}|${_opponent.replaceAll('|', '/')}|$_shiftLengthSeconds|${_shiftNumber ?? ''}',
    );
  }

  Future<void> _restore() async {
    final p = await SharedPreferences.getInstance();
    final meta = p.getString(_metaKey);
    if (meta != null) {
      final parts = meta.split('|');
      if (parts.length >= 3) {
        _teamName = parts[0];
        _opponent = parts[1];
        final parsed = int.tryParse(parts[2]);
        if (parsed != null && parsed > 0) {
          _shiftLengthSeconds = parsed;
        }
        if (parts.length >= 4 && parts[3].isNotEmpty) {
          final sn = int.tryParse(parts[3]);
          if (sn != null) _shiftNumber = sn;
        }
      }
    }
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
      final remaining = _shiftLengthSeconds - state;
      final matchup = _teamName.isEmpty
          ? 'Game $gameId'
          : _opponent.isEmpty
          ? _teamName
          : '$_teamName vs $_opponent';
      final shouldNotify = () {
        // Always notify first tick after start
        if (_lastNotifiedSecond == -1) return true;
        // Notify when crossing zero boundary (entering overtime) exactly once at boundary
        if (!_sentZeroBoundary && remaining <= 0) {
          _sentZeroBoundary = true;
          return true;
        }
        // Every 5-second interval (e.g., 295, 290, ... or overtime 5,10,15 over)
        if (state % 5 == 0) return true;
        return false;
      }();
      if (shouldNotify) {
        _lastNotifiedSecond = state;
        NotificationService.instance.showOrUpdateStopwatch(
          gameId: gameId,
          remainingSeconds: remaining,
          matchupTitle: matchup,
          shiftNumber: _shiftNumber,
        );
      }
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
    await NotificationService.instance.cancelStopwatch(gameId);
  }

  Future<void> reset() async {
    _t?.cancel();
    state = 0;
    _startedAt = null;
    _lastNotifiedSecond = -1;
    _sentZeroBoundary = false;
    final p = await SharedPreferences.getInstance();
    await p.remove(_prefKey);
    await p.remove(_elapsedKey);
    await p.remove(_metaKey);
    await NotificationService.instance.cancelStopwatch(gameId);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }
}
