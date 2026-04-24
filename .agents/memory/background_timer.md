# Background Timer — Implementation & Testing

## What Was Built

Accurate timer tracking when the app is backgrounded or force-quit.

### Implementation Details
- Added `timerStartTime` column to Games table.
- Timer start time saved when game begins.
- Current time calculated from `startTime + elapsed duration` (DateTime-based, not simple increment).
- `WidgetsBindingObserver` handles app lifecycle changes (pause/resume).
- Active players accumulate playing time during background.
- Timer state persisted to DB on app pause/resume.

## Manual Test Scenarios

### Scenario 1: Basic Background Persistence
1. Start timer in a game.
2. Background app for 30 seconds.
3. Return — timer should have advanced ~30 s.

### Scenario 2: Player Playing Time
1. Start game timer with active lineup; note playing times.
2. Background app for 1 minute.
3. Return — active players' playing time should have increased ~1 min.

### Scenario 3: Force-Quit Recovery
1. Start timer; note game time.
2. Force-quit app; wait 45 s.
3. Reopen and navigate to game — timer should show ~45 s more than noted.

### Scenario 4: Half-Time Transition with Background
1. Run timer near half duration; background app for a few minutes.
2. Return and start second half.
3. Second half should start fresh; total playing times preserved.
