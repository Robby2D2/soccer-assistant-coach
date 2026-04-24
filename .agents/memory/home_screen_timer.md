# Home Screen Timer Display

## Changes Made

- **Time format**: switched from elapsed time to time remaining in the half (e.g., "14:30" instead of "05:30").
- **Overtime**: shows `+MM:SS` prefix when past half duration.
- **Removed "time ago" display**: was showing "1hr ago", "30m ago" — removed as not useful.

## Technical Implementation

New method `_formatTimeRemaining`:
```dart
String _formatTimeRemaining(int gameTimeSeconds, int halfDurationSeconds) {
  final remaining = halfDurationSeconds - gameTimeSeconds;
  final isOvertime = remaining <= 0;
  final displaySeconds = isOvertime ? -remaining : remaining;
  final minutes = displaySeconds ~/ 60;
  final seconds = displaySeconds % 60;
  final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  return isOvertime ? '+$timeString' : timeString;
}
```

Uses `db.getTeamHalfDurationSeconds(team.id)` for the configured half duration; falls back to 20 min (1200 s).

Wrapped in a `FutureBuilder` to fetch half duration. Time updates in real-time for active games.

## Example Scenarios

| Game State | Old Display | New Display |
|------------|-------------|-------------|
| 5 min into half | "05:00" + "5m ago" | "15:00" |
| 18 min into half | "18:00" + "18m ago" | "02:00" |
| 22 min into half (overtime) | "22:00" + "22m ago" | "+02:00" |
