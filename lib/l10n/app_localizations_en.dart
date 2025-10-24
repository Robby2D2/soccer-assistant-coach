// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Soccer Assistant Coach';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsVibration => 'Alarm Vibration';

  @override
  String get settingsVibrationDescription =>
      'Vibrate device when shift alarm triggers';

  @override
  String get settingsNotifications => 'Notifications & Alarms';

  @override
  String get permissionNotificationsTitle => 'Allow Notifications';

  @override
  String get permissionNotificationsDescription =>
      'Enable shift alarms and game timers to alert you even when the app is closed.';

  @override
  String get permissionExactAlarmTitle => 'Exact Alarms';

  @override
  String get permissionExactAlarmDescription =>
      'Grant exact alarm permission so shift alarms fire at the precise second (Android 12+).';

  @override
  String get permissionRequestButton => 'Request Permissions';

  @override
  String get permissionGranted => 'Permission Granted';

  @override
  String get permissionDenied => 'Permission Denied';

  @override
  String get vibrationEnabledStatus => 'Vibration enabled';

  @override
  String get vibrationDisabledStatus => 'Vibration disabled';

  @override
  String get stopAlarmAction => 'Stop Alarm';

  @override
  String get alarmDismissed => 'Alarm dismissed';

  @override
  String get alarmDismissedBody => 'Countdown continuing…';

  @override
  String get alarmCustomization => 'Alarm Customization';

  @override
  String get shiftAlarmsEnabled => 'Shift End Alarms';

  @override
  String get shiftAlarmsDescription => 'Play alarm when shift time expires';

  @override
  String get halftimeAlarmsEnabled => 'Halftime Alarms';

  @override
  String get halftimeAlarmsDescription =>
      'Play alarm at halftime in traditional games';

  @override
  String get alarmSounds => 'Alarm Sounds';

  @override
  String get shiftAlarmSound => 'Shift End Sound';

  @override
  String get halftimeAlarmSound => 'Halftime Sound';

  @override
  String get alarmVolume => 'Volume';

  @override
  String get alarmDuration => 'Alarm Duration';

  @override
  String get alarmDurationDescription =>
      'How long alarms sound before stopping';

  @override
  String get previewSound => 'Preview';

  @override
  String get seconds => 'seconds';

  @override
  String get language => 'Language';

  @override
  String get languageDescription => 'Select the application language';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get done => 'Done';

  @override
  String get reset => 'Reset';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get teams => 'Teams';

  @override
  String get createTeam => 'Create Team';

  @override
  String get teamName => 'Team name';

  @override
  String get manageTeams => 'Manage Teams';

  @override
  String get manageSeasons => 'Manage Seasons';

  @override
  String get noActiveSeasons => 'No Active Season';

  @override
  String get createSeason => 'Create Season';

  @override
  String get archived => 'Archived';

  @override
  String get traditional => 'Traditional';

  @override
  String get shiftMode => 'Shift Mode';

  @override
  String get showArchived => 'Show Archived';

  @override
  String get hideArchived => 'Hide Archived';

  @override
  String get archive => 'Archive';

  @override
  String get restore => 'Restore';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get inputMetrics => 'Input Metrics';

  @override
  String get viewMetrics => 'View Metrics';

  @override
  String get attendance => 'Attendance';

  @override
  String get formation => 'Formation';

  @override
  String get endGame => 'End Game';

  @override
  String get databaseDiagnostics => 'Database Diagnostics';

  @override
  String get noArchivedTeams => 'No Archived Teams';

  @override
  String get noTeamsYet => 'No Teams Yet';

  @override
  String get noArchivedTeamsDescription =>
      'You don\'t have any archived teams.';

  @override
  String get noTeamsYetDescription =>
      'Create your first team to start managing players, formations, and games.';

  @override
  String get noActiveSeasonFound =>
      'No active season found. Please create a season first.';

  @override
  String creatingTeamFor(String seasonName) {
    return 'Creating team for: $seasonName';
  }

  @override
  String get noActiveSeason => 'No Active Season';

  @override
  String get createSeasonToManageTeams =>
      'Create a season to start managing teams.';

  @override
  String errorLoadingTeams(String error) {
    return 'Error loading teams: $error';
  }

  @override
  String get restoreTeam => 'Restore team';

  @override
  String get archiveTeam => 'Archive team';

  @override
  String get editTeam => 'Edit team';

  @override
  String errorLoadingSeason(String error) {
    return 'Error loading season: $error';
  }

  @override
  String get games => 'Games';

  @override
  String get createGame => 'Create Game';

  @override
  String get win => 'Win';

  @override
  String get loss => 'Loss';

  @override
  String get draw => 'Draw';

  @override
  String get noArchivedGames => 'No Archived Games';

  @override
  String get noGamesYet => 'No Games Yet';

  @override
  String get noArchivedGamesDescription =>
      'You don\'t have any archived games.';

  @override
  String get noGamesYetDescription =>
      'Schedule your first game to start tracking match performance and player statistics.';

  @override
  String get startGame => 'Start Game';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get start => 'Start';

  @override
  String get firstHalf => '1st Half';

  @override
  String get secondHalf => '2nd Half';

  @override
  String get halftime => 'Halftime';

  @override
  String get overtime => 'Overtime';

  @override
  String get completeGame => 'Complete Game';

  @override
  String get completing => 'Completing...';

  @override
  String get players => 'Players';

  @override
  String get noPlayersYet => 'No Players Yet';

  @override
  String get addPlayersDescription =>
      'Add players to your team roster to get started with lineup management.';

  @override
  String get addPlayer => 'Add Player';

  @override
  String get importCsv => 'Import CSV';

  @override
  String get newPlayer => 'New';

  @override
  String get player => 'Player';

  @override
  String get formations => 'Formations';

  @override
  String get createFormation => 'Create Formation';

  @override
  String get metrics => 'Metrics';

  @override
  String get resetToDefaults => 'Reset to Defaults';

  @override
  String get resetSettings => 'Reset Settings';

  @override
  String get resetConfirmation =>
      'Are you sure you want to reset all alarm settings to their default values? This action cannot be undone.';

  @override
  String get settingsResetToDefaults => 'Settings reset to defaults';

  @override
  String get currentConfiguration => 'Current Configuration';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get runDiagnostics => 'Run Diagnostics';

  @override
  String get exportDatabase => 'Export Database';

  @override
  String get importDatabase => 'Import Database';

  @override
  String get resetDatabase => 'Reset Database';

  @override
  String get diagnosticResults => 'Diagnostic Results';

  @override
  String get databaseDiagnosticTool => 'Database Diagnostic Tool';

  @override
  String get databaseDiagnosticDescription =>
      'This tool will help identify database issues and check if your teams are still in the database.';

  @override
  String get createTestTeam => 'Create Test Team';

  @override
  String get runningDiagnostics => 'Running diagnostics...';

  @override
  String get databaseExported => 'Database exported successfully';

  @override
  String get databaseImported => 'Database imported successfully';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get importFailed => 'Import failed';

  @override
  String get cannotBeUndone => 'THIS CANNOT BE UNDONE!';

  @override
  String get startOverWarning =>
      'Only proceed if you want to completely start over with a fresh database.';

  @override
  String get teamLogo => 'Team Logo';

  @override
  String get selectTeamLogo => 'Select Team Logo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get teamColorPalette => 'Team Color Palette';

  @override
  String get pickColor => 'Pick Color';

  @override
  String get advancedPicker => 'Advanced Picker';

  @override
  String get color => 'Color';

  @override
  String get teamManagementHub => 'Team Management Hub';

  @override
  String get teamManagement => 'Team Management';

  @override
  String get gameManagement => 'Game Management';

  @override
  String get manageTeamRosterDescription =>
      'Manage team roster and player status';

  @override
  String get setupTacticalFormationsDescription =>
      'Set up tactical formations and positions';

  @override
  String get scheduleGamesDescription =>
      'Schedule games and track match history';

  @override
  String get viewPlayerStatisticsDescription =>
      'View all-time player statistics and performance';

  @override
  String get teamMetrics => 'Team Metrics';

  @override
  String get activeGames => 'Active Games';

  @override
  String get noActiveGames => 'No Active Games';

  @override
  String get startGameForQuickAccess =>
      'Start a game to see it here for quick access';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String errorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String get languageChangedTo => 'Language changed to';

  @override
  String get close => 'Close';

  @override
  String get noFormationsYet => 'No Formations Yet';

  @override
  String get noFormationsYetDescription =>
      'Create tactical formations to organize your team\'s positioning and strategy.';

  @override
  String get createFormationTooltip => 'Create formation';

  @override
  String get editFormation => 'Edit Formation';

  @override
  String get deleteFormation => 'Delete Formation';

  @override
  String get deleteFormationTitle => 'Delete formation?';

  @override
  String deleteFormationMessage(String formationName) {
    return 'Delete \"$formationName\"?';
  }

  @override
  String playersCount(int count) {
    return '$count players';
  }

  @override
  String get noDate => 'No date';

  @override
  String get opponent => 'Opponent';

  @override
  String get pickDateTime => 'Pick date/time';

  @override
  String get noFormation => 'No formation';

  @override
  String get manageFormations => 'Manage formations';

  @override
  String get manageFormationsTooltip => 'Manage formations';

  @override
  String get noPlayersFoundForTeam => 'No players found for this team.';

  @override
  String playerIdLabel(int playerId) {
    return 'Player ID: $playerId';
  }

  @override
  String get manage => 'Manage';

  @override
  String get selectMetricType => 'Select Metric Type';

  @override
  String get quickEntry => 'Quick Entry';

  @override
  String get viewOverview => 'View Overview';

  @override
  String addedMetric(String metric) {
    return 'Added $metric';
  }

  @override
  String removedMetric(String metric) {
    return 'Removed $metric';
  }

  @override
  String quickMetricEntry(String metric) {
    return 'Quick $metric Entry';
  }

  @override
  String tapPlayersWhoScored(String metric) {
    return 'Tap players who scored ${metric}s:';
  }

  @override
  String get apply => 'Apply';

  @override
  String addedMultipleMetrics(int count, String metric) {
    return 'Added $count ${metric}s';
  }

  @override
  String get goal => 'Goal';

  @override
  String get assist => 'Assist';

  @override
  String get importRosterCsv => 'Import Roster CSV';

  @override
  String get pasteCsvWithHeader =>
      'Paste CSV with header: firstName,lastName,jerseyNumber (jersey number is optional)';

  @override
  String get csvHintText =>
      'firstName,lastName,jerseyNumber\nJane,Doe,10\nJohn,Smith,\nAlex,Johnson,7';

  @override
  String previewRows(int count) {
    return 'Preview: $count rows';
  }

  @override
  String jerseyNumber(String number) {
    return 'Jersey #: $number';
  }

  @override
  String get jerseyNA => 'N/A';

  @override
  String get import => 'Import';

  @override
  String get creatingSeason => 'Creating season...';

  @override
  String get seasonCreatedSuccessfully => 'Season created successfully!';

  @override
  String errorCreatingSeason(String error) {
    return 'Error creating season: $error';
  }

  @override
  String get cloningSeason => 'Cloning season...';

  @override
  String get seasonClonedSuccessfully => 'Season cloned successfully!';

  @override
  String errorCloningSeason(String error) {
    return 'Error cloning season: $error';
  }

  @override
  String get seasonActivated => 'Season activated!';

  @override
  String errorActivatingSeason(String error) {
    return 'Error activating season: $error';
  }

  @override
  String get archiveSeason => 'Archive Season';

  @override
  String get seasonArchived => 'Season archived!';

  @override
  String errorArchivingSeason(String error) {
    return 'Error archiving season: $error';
  }

  @override
  String get seasonUpdated => 'Season updated!';

  @override
  String errorUpdatingSeason(String error) {
    return 'Error updating season: $error';
  }

  @override
  String get activate => 'Activate';

  @override
  String get cloneSeason => 'Clone Season';

  @override
  String get createNewSeason => 'Create New Season';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDateOptional => 'End Date (Optional)';

  @override
  String get noExistingTeamsToClone => 'No existing teams to clone';

  @override
  String cloneSeasonTitle(String seasonName) {
    return 'Clone \"$seasonName\"';
  }
}
