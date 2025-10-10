# Home Screen Timer Display Update

## Changes Made

### ✅ **Updated Time Display Format**
- **Before**: Showed elapsed time (e.g., "05:30" for 5 minutes 30 seconds elapsed)
- **After**: Shows time remaining in the half (e.g., "14:30" for 14 minutes 30 seconds remaining)

### ✅ **Removed "Time Ago" Display** 
- **Before**: Showed "1hr ago", "30m ago", etc. for when the game started
- **After**: Removed this display as it wasn't providing valuable information

### ✅ **Added Overtime Support**
- **Normal Time**: Shows remaining time (e.g., "15:30")
- **Overtime**: Shows overtime with + prefix (e.g., "+02:15" for 2 minutes 15 seconds over)

## Technical Implementation

### New Method: `_formatTimeRemaining`
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

### Integration with Team Settings
- Uses `db.getTeamHalfDurationSeconds(team.id)` to get the configured half duration
- Supports different teams having different half durations
- Falls back to 20 minutes (1200 seconds) if no configuration found

### UI Updates
- Wrapped the time display in a `FutureBuilder` to fetch half duration
- Maintains the same styling and positioning as before
- Time continues to update in real-time for active games

## User Experience Improvements

### ✅ **Consistent with Game Detail Page**
- Home screen now shows the same time format as the traditional game screen
- Users see consistent time remaining information across the app

### ✅ **More Actionable Information**
- Remaining time is more useful for coaches than elapsed time
- Immediately shows if a half is in overtime
- Helps coaches plan substitutions and game management

### ✅ **Cleaner Interface**
- Removed redundant "time ago" information
- Focus is on the most important information: time remaining
- Reduced visual clutter on the home screen

## Example Display Scenarios

| Game State | Old Display | New Display |
|------------|-------------|-------------|
| 5 min into half | "05:00" + "5m ago" | "15:00" |
| 18 min into half | "18:00" + "18m ago" | "02:00" |
| 22 min into half (overtime) | "22:00" + "22m ago" | "+02:00" |
| Halftime break | "20:00" + "20m ago" | "00:00" |

The updates provide coaches with more relevant, actionable information while maintaining a clean and consistent interface across the application.