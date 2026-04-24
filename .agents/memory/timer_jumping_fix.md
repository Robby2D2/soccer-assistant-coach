# Timer Jumping Fix

## Root Cause

Two conflicting time-calculation methods running simultaneously:
1. Simple per-second increment (`_gameTime + 1`)
2. `calculateCurrentGameTime()` recalculating from DB every second

Small delays between the increment and the DB recalculation caused visible jumps, especially past half duration.

Secondary issue: home screen was rebuilding FutureBuilders frequently due to DB writes every 5 seconds.

## Fix

**Game screen**: use simple increment for normal operation; only call `calculateCurrentGameTime()` when actually resuming from background.

```dart
// Before (called every second — caused jumps)
_updateGameTimeFromBackground();

// After (stable)
setState(() { _gameTime = _gameTime + 1; });
```

**Home screen**: calculate display time once per rebuild from direct DateTime math instead of inside a FutureBuilder.

```dart
final gameTimeForDisplay = game.isGameActive && game.timerStartTime != null
    ? game.gameTimeSeconds + DateTime.now().difference(game.timerStartTime!).inSeconds
    : game.gameTimeSeconds;
```

## What Was Preserved
- Background persistence still works (lifecycle observer + DB save on pause).
- `calculateCurrentGameTime()` still called on resume-from-background.
- Game time still periodically saved to DB every 5 seconds.
