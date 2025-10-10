# Background Timer Test Instructions

## Test Scenario 1: Basic Background Timer Persistence

### Setup:
1. Open the app
2. Navigate to a team in Traditional mode
3. Create or open a game
4. Start the timer
5. Verify timer is running and counting

### Test Steps:
1. **Start Timer**: Tap the Start button and verify timer begins counting
2. **Note Current Time**: Record the current timer value (e.g., 02:35)
3. **Background App**: Press home button to background the app for 30 seconds
4. **Return to App**: Tap the app icon to return to the game screen
5. **Verify Continuity**: Confirm timer has advanced by approximately 30 seconds

**Expected Result**: Timer should show approximately 03:05 (original time + 30 seconds)

## Test Scenario 2: Player Playing Time Accuracy

### Setup:
1. Start a game timer with players in active lineup
2. Note the playing time for active players

### Test Steps:
1. **Start Timer**: Begin game timer with active lineup
2. **Note Playing Times**: Record current playing time for active players
3. **Background App**: Send app to background for 1 minute
4. **Return to App**: Return and check playing times
5. **Verify Accumulation**: Confirm playing times increased by ~1 minute

**Expected Result**: Active players' playing time should increase by background duration

## Test Scenario 3: App Termination Recovery

### Setup:
1. Start game timer
2. Record current game time

### Test Steps:
1. **Start Timer**: Begin game timer
2. **Note Time**: Record current game time
3. **Force Quit App**: Swipe up and force close the app
4. **Wait**: Wait 45 seconds
5. **Reopen App**: Launch app and navigate back to game
6. **Verify Recovery**: Check if timer resumed from where it left off

**Expected Result**: Timer should resume and show approximately 45 seconds more than noted time

## Test Scenario 4: Half Time Transition with Background

### Setup:
1. Start first half timer
2. Let it run close to half duration

### Test Steps:
1. **Near Half Time**: Run timer to near half duration
2. **Background App**: Send to background for a few minutes
3. **Return**: Come back to app
4. **Start Second Half**: Transition to second half
5. **Verify State**: Ensure second half timer works correctly

**Expected Result**: Second half should start fresh while preserving total playing times

## Implementation Details Verified:

✅ **Database Schema**: Added `timerStartTime` column to Games table
✅ **Timer Persistence**: Timer start time saved when game begins
✅ **Background Calculation**: Current time calculated from start time + elapsed duration
✅ **App Lifecycle Monitoring**: WidgetsBindingObserver handles app state changes
✅ **Playing Time Accuracy**: Background time added to active players' accumulated time
✅ **Database Updates**: Timer state persisted on app pause/resume

## Key Features Implemented:

1. **Accurate Time Tracking**: Uses DateTime-based calculation instead of simple incrementing
2. **Background Persistence**: Timer continues counting even when app is closed
3. **Playing Time Continuity**: Active players accumulate playing time during background
4. **State Recovery**: App recovers timer state when returning from background
5. **Database Persistence**: All timer state saved to database for reliability

The implementation ensures the stopwatch keeps running accurately even if the app is closed, and when returning to the app, the time remaining continues counting down as if the app never stopped running.