import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Soccer Assistant Coach'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsVibration.
  ///
  /// In en, this message translates to:
  /// **'Alarm Vibration'**
  String get settingsVibration;

  /// No description provided for @settingsVibrationDescription.
  ///
  /// In en, this message translates to:
  /// **'Vibrate device when shift alarm triggers'**
  String get settingsVibrationDescription;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications & Alarms'**
  String get settingsNotifications;

  /// No description provided for @permissionNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications'**
  String get permissionNotificationsTitle;

  /// No description provided for @permissionNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Enable shift alarms and game timers to alert you even when the app is closed.'**
  String get permissionNotificationsDescription;

  /// No description provided for @permissionExactAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Exact Alarms'**
  String get permissionExactAlarmTitle;

  /// No description provided for @permissionExactAlarmDescription.
  ///
  /// In en, this message translates to:
  /// **'Grant exact alarm permission so shift alarms fire at the precise second (Android 12+).'**
  String get permissionExactAlarmDescription;

  /// No description provided for @permissionRequestButton.
  ///
  /// In en, this message translates to:
  /// **'Request Permissions'**
  String get permissionRequestButton;

  /// No description provided for @permissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Permission Granted'**
  String get permissionGranted;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permissionDenied;

  /// No description provided for @vibrationEnabledStatus.
  ///
  /// In en, this message translates to:
  /// **'Vibration enabled'**
  String get vibrationEnabledStatus;

  /// No description provided for @vibrationDisabledStatus.
  ///
  /// In en, this message translates to:
  /// **'Vibration disabled'**
  String get vibrationDisabledStatus;

  /// No description provided for @stopAlarmAction.
  ///
  /// In en, this message translates to:
  /// **'Stop Alarm'**
  String get stopAlarmAction;

  /// No description provided for @alarmDismissed.
  ///
  /// In en, this message translates to:
  /// **'Alarm dismissed'**
  String get alarmDismissed;

  /// No description provided for @alarmDismissedBody.
  ///
  /// In en, this message translates to:
  /// **'Countdown continuing…'**
  String get alarmDismissedBody;

  /// No description provided for @alarmCustomization.
  ///
  /// In en, this message translates to:
  /// **'Alarm Customization'**
  String get alarmCustomization;

  /// No description provided for @shiftAlarmsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Shift End Alarms'**
  String get shiftAlarmsEnabled;

  /// No description provided for @shiftAlarmsDescription.
  ///
  /// In en, this message translates to:
  /// **'Play alarm when shift time expires'**
  String get shiftAlarmsDescription;

  /// No description provided for @halftimeAlarmsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Halftime Alarms'**
  String get halftimeAlarmsEnabled;

  /// No description provided for @halftimeAlarmsDescription.
  ///
  /// In en, this message translates to:
  /// **'Play alarm at halftime in traditional games'**
  String get halftimeAlarmsDescription;

  /// No description provided for @alarmSounds.
  ///
  /// In en, this message translates to:
  /// **'Alarm Sounds'**
  String get alarmSounds;

  /// No description provided for @shiftAlarmSound.
  ///
  /// In en, this message translates to:
  /// **'Shift End Sound'**
  String get shiftAlarmSound;

  /// No description provided for @halftimeAlarmSound.
  ///
  /// In en, this message translates to:
  /// **'Halftime Sound'**
  String get halftimeAlarmSound;

  /// No description provided for @alarmVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get alarmVolume;

  /// No description provided for @alarmDuration.
  ///
  /// In en, this message translates to:
  /// **'Alarm Duration'**
  String get alarmDuration;

  /// No description provided for @alarmDurationDescription.
  ///
  /// In en, this message translates to:
  /// **'How long alarms sound before stopping'**
  String get alarmDurationDescription;

  /// No description provided for @previewSound.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewSound;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Select the application language'**
  String get languageDescription;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @teams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get teams;

  /// No description provided for @createTeam.
  ///
  /// In en, this message translates to:
  /// **'Create Team'**
  String get createTeam;

  /// No description provided for @teamName.
  ///
  /// In en, this message translates to:
  /// **'Team name'**
  String get teamName;

  /// No description provided for @manageTeams.
  ///
  /// In en, this message translates to:
  /// **'Manage Teams'**
  String get manageTeams;

  /// No description provided for @manageSeasons.
  ///
  /// In en, this message translates to:
  /// **'Manage Seasons'**
  String get manageSeasons;

  /// No description provided for @noActiveSeasons.
  ///
  /// In en, this message translates to:
  /// **'No Active Season'**
  String get noActiveSeasons;

  /// No description provided for @createSeason.
  ///
  /// In en, this message translates to:
  /// **'Create Season'**
  String get createSeason;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @traditional.
  ///
  /// In en, this message translates to:
  /// **'Traditional'**
  String get traditional;

  /// No description provided for @shiftMode.
  ///
  /// In en, this message translates to:
  /// **'Shift Mode'**
  String get shiftMode;

  /// No description provided for @showArchived.
  ///
  /// In en, this message translates to:
  /// **'Show Archived'**
  String get showArchived;

  /// No description provided for @hideArchived.
  ///
  /// In en, this message translates to:
  /// **'Hide Archived'**
  String get hideArchived;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @inputMetrics.
  ///
  /// In en, this message translates to:
  /// **'Input Metrics'**
  String get inputMetrics;

  /// No description provided for @viewMetrics.
  ///
  /// In en, this message translates to:
  /// **'View Metrics'**
  String get viewMetrics;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @formation.
  ///
  /// In en, this message translates to:
  /// **'Formation'**
  String get formation;

  /// No description provided for @endGame.
  ///
  /// In en, this message translates to:
  /// **'End Game'**
  String get endGame;

  /// No description provided for @databaseDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Database Diagnostics'**
  String get databaseDiagnostics;

  /// No description provided for @noArchivedTeams.
  ///
  /// In en, this message translates to:
  /// **'No Archived Teams'**
  String get noArchivedTeams;

  /// No description provided for @noTeamsYet.
  ///
  /// In en, this message translates to:
  /// **'No Teams Yet'**
  String get noTeamsYet;

  /// No description provided for @noArchivedTeamsDescription.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any archived teams.'**
  String get noArchivedTeamsDescription;

  /// No description provided for @noTeamsYetDescription.
  ///
  /// In en, this message translates to:
  /// **'Create your first team to start managing players, formations, and games.'**
  String get noTeamsYetDescription;

  /// No description provided for @noActiveSeasonFound.
  ///
  /// In en, this message translates to:
  /// **'No active season found. Please create a season first.'**
  String get noActiveSeasonFound;

  /// No description provided for @creatingTeamFor.
  ///
  /// In en, this message translates to:
  /// **'Creating team for: {seasonName}'**
  String creatingTeamFor(String seasonName);

  /// No description provided for @noActiveSeason.
  ///
  /// In en, this message translates to:
  /// **'No Active Season'**
  String get noActiveSeason;

  /// No description provided for @createSeasonToManageTeams.
  ///
  /// In en, this message translates to:
  /// **'Create a season to start managing teams.'**
  String get createSeasonToManageTeams;

  /// No description provided for @errorLoadingTeams.
  ///
  /// In en, this message translates to:
  /// **'Error loading teams: {error}'**
  String errorLoadingTeams(String error);

  /// No description provided for @restoreTeam.
  ///
  /// In en, this message translates to:
  /// **'Restore team'**
  String get restoreTeam;

  /// No description provided for @archiveTeam.
  ///
  /// In en, this message translates to:
  /// **'Archive team'**
  String get archiveTeam;

  /// No description provided for @editTeam.
  ///
  /// In en, this message translates to:
  /// **'Edit team'**
  String get editTeam;

  /// No description provided for @errorLoadingSeason.
  ///
  /// In en, this message translates to:
  /// **'Error loading season: {error}'**
  String errorLoadingSeason(String error);

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @createGame.
  ///
  /// In en, this message translates to:
  /// **'Create Game'**
  String get createGame;

  /// No description provided for @win.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get win;

  /// No description provided for @loss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get loss;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// No description provided for @noArchivedGames.
  ///
  /// In en, this message translates to:
  /// **'No Archived Games'**
  String get noArchivedGames;

  /// No description provided for @noGamesYet.
  ///
  /// In en, this message translates to:
  /// **'No Games Yet'**
  String get noGamesYet;

  /// No description provided for @noArchivedGamesDescription.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any archived games.'**
  String get noArchivedGamesDescription;

  /// No description provided for @noGamesYetDescription.
  ///
  /// In en, this message translates to:
  /// **'Schedule your first game to start tracking match performance and player statistics.'**
  String get noGamesYetDescription;

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get startGame;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @firstHalf.
  ///
  /// In en, this message translates to:
  /// **'1st Half'**
  String get firstHalf;

  /// No description provided for @secondHalf.
  ///
  /// In en, this message translates to:
  /// **'2nd Half'**
  String get secondHalf;

  /// No description provided for @halftime.
  ///
  /// In en, this message translates to:
  /// **'Halftime'**
  String get halftime;

  /// No description provided for @overtime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtime;

  /// No description provided for @completeGame.
  ///
  /// In en, this message translates to:
  /// **'Complete Game'**
  String get completeGame;

  /// No description provided for @completing.
  ///
  /// In en, this message translates to:
  /// **'Completing...'**
  String get completing;

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get players;

  /// No description provided for @noPlayersYet.
  ///
  /// In en, this message translates to:
  /// **'No Players Yet'**
  String get noPlayersYet;

  /// No description provided for @addPlayersDescription.
  ///
  /// In en, this message translates to:
  /// **'Add players to your team roster to get started with lineup management.'**
  String get addPlayersDescription;

  /// No description provided for @addPlayer.
  ///
  /// In en, this message translates to:
  /// **'Add Player'**
  String get addPlayer;

  /// No description provided for @importCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get importCsv;

  /// No description provided for @newPlayer.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newPlayer;

  /// No description provided for @player.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player;

  /// No description provided for @formations.
  ///
  /// In en, this message translates to:
  /// **'Formations'**
  String get formations;

  /// No description provided for @createFormation.
  ///
  /// In en, this message translates to:
  /// **'Create Formation'**
  String get createFormation;

  /// No description provided for @metrics.
  ///
  /// In en, this message translates to:
  /// **'Metrics'**
  String get metrics;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get resetToDefaults;

  /// No description provided for @resetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get resetSettings;

  /// No description provided for @resetConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all alarm settings to their default values? This action cannot be undone.'**
  String get resetConfirmation;

  /// No description provided for @settingsResetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Settings reset to defaults'**
  String get settingsResetToDefaults;

  /// No description provided for @currentConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Current Configuration'**
  String get currentConfiguration;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @runDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Run Diagnostics'**
  String get runDiagnostics;

  /// No description provided for @exportDatabase.
  ///
  /// In en, this message translates to:
  /// **'Export Database'**
  String get exportDatabase;

  /// No description provided for @importDatabase.
  ///
  /// In en, this message translates to:
  /// **'Import Database'**
  String get importDatabase;

  /// No description provided for @resetDatabase.
  ///
  /// In en, this message translates to:
  /// **'Reset Database'**
  String get resetDatabase;

  /// No description provided for @diagnosticResults.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic Results'**
  String get diagnosticResults;

  /// No description provided for @databaseDiagnosticTool.
  ///
  /// In en, this message translates to:
  /// **'Database Diagnostic Tool'**
  String get databaseDiagnosticTool;

  /// No description provided for @databaseDiagnosticDescription.
  ///
  /// In en, this message translates to:
  /// **'This tool will help identify database issues and check if your teams are still in the database.'**
  String get databaseDiagnosticDescription;

  /// No description provided for @createTestTeam.
  ///
  /// In en, this message translates to:
  /// **'Create Test Team'**
  String get createTestTeam;

  /// No description provided for @runningDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Running diagnostics...'**
  String get runningDiagnostics;

  /// No description provided for @databaseExported.
  ///
  /// In en, this message translates to:
  /// **'Database exported successfully'**
  String get databaseExported;

  /// No description provided for @databaseImported.
  ///
  /// In en, this message translates to:
  /// **'Database imported successfully'**
  String get databaseImported;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'THIS CANNOT BE UNDONE!'**
  String get cannotBeUndone;

  /// No description provided for @startOverWarning.
  ///
  /// In en, this message translates to:
  /// **'Only proceed if you want to completely start over with a fresh database.'**
  String get startOverWarning;

  /// No description provided for @teamLogo.
  ///
  /// In en, this message translates to:
  /// **'Team Logo'**
  String get teamLogo;

  /// No description provided for @selectTeamLogo.
  ///
  /// In en, this message translates to:
  /// **'Select Team Logo'**
  String get selectTeamLogo;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @teamColorPalette.
  ///
  /// In en, this message translates to:
  /// **'Team Color Palette'**
  String get teamColorPalette;

  /// No description provided for @pickColor.
  ///
  /// In en, this message translates to:
  /// **'Pick Color'**
  String get pickColor;

  /// No description provided for @advancedPicker.
  ///
  /// In en, this message translates to:
  /// **'Advanced Picker'**
  String get advancedPicker;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @teamManagementHub.
  ///
  /// In en, this message translates to:
  /// **'Team Management Hub'**
  String get teamManagementHub;

  /// No description provided for @teamManagement.
  ///
  /// In en, this message translates to:
  /// **'Team Management'**
  String get teamManagement;

  /// No description provided for @gameManagement.
  ///
  /// In en, this message translates to:
  /// **'Game Management'**
  String get gameManagement;

  /// No description provided for @manageTeamRosterDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage team roster and player status'**
  String get manageTeamRosterDescription;

  /// No description provided for @setupTacticalFormationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Set up tactical formations and positions'**
  String get setupTacticalFormationsDescription;

  /// No description provided for @scheduleGamesDescription.
  ///
  /// In en, this message translates to:
  /// **'Schedule games and track match history'**
  String get scheduleGamesDescription;

  /// No description provided for @viewPlayerStatisticsDescription.
  ///
  /// In en, this message translates to:
  /// **'View all-time player statistics and performance'**
  String get viewPlayerStatisticsDescription;

  /// No description provided for @teamMetrics.
  ///
  /// In en, this message translates to:
  /// **'Team Metrics'**
  String get teamMetrics;

  /// No description provided for @activeGames.
  ///
  /// In en, this message translates to:
  /// **'Active Games'**
  String get activeGames;

  /// No description provided for @noActiveGames.
  ///
  /// In en, this message translates to:
  /// **'No Active Games'**
  String get noActiveGames;

  /// No description provided for @startGameForQuickAccess.
  ///
  /// In en, this message translates to:
  /// **'Start a game to see it here for quick access'**
  String get startGameForQuickAccess;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @errorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithDetails(String error);

  /// No description provided for @languageChangedTo.
  ///
  /// In en, this message translates to:
  /// **'Language changed to'**
  String get languageChangedTo;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @noFormationsYet.
  ///
  /// In en, this message translates to:
  /// **'No Formations Yet'**
  String get noFormationsYet;

  /// No description provided for @noFormationsYetDescription.
  ///
  /// In en, this message translates to:
  /// **'Create tactical formations to organize your team\'s positioning and strategy.'**
  String get noFormationsYetDescription;

  /// No description provided for @createFormationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create formation'**
  String get createFormationTooltip;

  /// No description provided for @editFormation.
  ///
  /// In en, this message translates to:
  /// **'Edit Formation'**
  String get editFormation;

  /// No description provided for @deleteFormation.
  ///
  /// In en, this message translates to:
  /// **'Delete Formation'**
  String get deleteFormation;

  /// No description provided for @deleteFormationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete formation?'**
  String get deleteFormationTitle;

  /// No description provided for @deleteFormationMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{formationName}\"?'**
  String deleteFormationMessage(String formationName);

  /// No description provided for @playersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} players'**
  String playersCount(int count);

  /// No description provided for @noDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get noDate;

  /// No description provided for @opponent.
  ///
  /// In en, this message translates to:
  /// **'Opponent'**
  String get opponent;

  /// No description provided for @pickDateTime.
  ///
  /// In en, this message translates to:
  /// **'Pick date/time'**
  String get pickDateTime;

  /// No description provided for @noFormation.
  ///
  /// In en, this message translates to:
  /// **'No formation'**
  String get noFormation;

  /// No description provided for @manageFormations.
  ///
  /// In en, this message translates to:
  /// **'Manage formations'**
  String get manageFormations;

  /// No description provided for @manageFormationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Manage formations'**
  String get manageFormationsTooltip;

  /// No description provided for @noPlayersFoundForTeam.
  ///
  /// In en, this message translates to:
  /// **'No players found for this team.'**
  String get noPlayersFoundForTeam;

  /// No description provided for @playerIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Player ID: {playerId}'**
  String playerIdLabel(int playerId);

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @selectMetricType.
  ///
  /// In en, this message translates to:
  /// **'Select Metric Type'**
  String get selectMetricType;

  /// No description provided for @quickEntry.
  ///
  /// In en, this message translates to:
  /// **'Quick Entry'**
  String get quickEntry;

  /// No description provided for @viewOverview.
  ///
  /// In en, this message translates to:
  /// **'View Overview'**
  String get viewOverview;

  /// No description provided for @addedMetric.
  ///
  /// In en, this message translates to:
  /// **'Added {metric}'**
  String addedMetric(String metric);

  /// No description provided for @removedMetric.
  ///
  /// In en, this message translates to:
  /// **'Removed {metric}'**
  String removedMetric(String metric);

  /// No description provided for @quickMetricEntry.
  ///
  /// In en, this message translates to:
  /// **'Quick {metric} Entry'**
  String quickMetricEntry(String metric);

  /// No description provided for @tapPlayersWhoScored.
  ///
  /// In en, this message translates to:
  /// **'Tap players who scored {metric}s:'**
  String tapPlayersWhoScored(String metric);

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @addedMultipleMetrics.
  ///
  /// In en, this message translates to:
  /// **'Added {count} {metric}s'**
  String addedMultipleMetrics(int count, String metric);

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// No description provided for @assist.
  ///
  /// In en, this message translates to:
  /// **'Assist'**
  String get assist;

  /// No description provided for @importRosterCsv.
  ///
  /// In en, this message translates to:
  /// **'Import Roster CSV'**
  String get importRosterCsv;

  /// No description provided for @pasteCsvWithHeader.
  ///
  /// In en, this message translates to:
  /// **'Paste CSV with header: firstName,lastName,jerseyNumber (jersey number is optional)'**
  String get pasteCsvWithHeader;

  /// No description provided for @csvHintText.
  ///
  /// In en, this message translates to:
  /// **'firstName,lastName,jerseyNumber\nJane,Doe,10\nJohn,Smith,\nAlex,Johnson,7'**
  String get csvHintText;

  /// No description provided for @previewRows.
  ///
  /// In en, this message translates to:
  /// **'Preview: {count} rows'**
  String previewRows(int count);

  /// No description provided for @jerseyNumber.
  ///
  /// In en, this message translates to:
  /// **'Jersey #: {number}'**
  String jerseyNumber(String number);

  /// No description provided for @jerseyNA.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get jerseyNA;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @creatingSeason.
  ///
  /// In en, this message translates to:
  /// **'Creating season...'**
  String get creatingSeason;

  /// No description provided for @seasonCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Season created successfully!'**
  String get seasonCreatedSuccessfully;

  /// No description provided for @errorCreatingSeason.
  ///
  /// In en, this message translates to:
  /// **'Error creating season: {error}'**
  String errorCreatingSeason(String error);

  /// No description provided for @cloningSeason.
  ///
  /// In en, this message translates to:
  /// **'Cloning season...'**
  String get cloningSeason;

  /// No description provided for @seasonClonedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Season cloned successfully!'**
  String get seasonClonedSuccessfully;

  /// No description provided for @errorCloningSeason.
  ///
  /// In en, this message translates to:
  /// **'Error cloning season: {error}'**
  String errorCloningSeason(String error);

  /// No description provided for @seasonActivated.
  ///
  /// In en, this message translates to:
  /// **'Season activated!'**
  String get seasonActivated;

  /// No description provided for @errorActivatingSeason.
  ///
  /// In en, this message translates to:
  /// **'Error activating season: {error}'**
  String errorActivatingSeason(String error);

  /// No description provided for @archiveSeason.
  ///
  /// In en, this message translates to:
  /// **'Archive Season'**
  String get archiveSeason;

  /// No description provided for @seasonArchived.
  ///
  /// In en, this message translates to:
  /// **'Season archived!'**
  String get seasonArchived;

  /// No description provided for @errorArchivingSeason.
  ///
  /// In en, this message translates to:
  /// **'Error archiving season: {error}'**
  String errorArchivingSeason(String error);

  /// No description provided for @seasonUpdated.
  ///
  /// In en, this message translates to:
  /// **'Season updated!'**
  String get seasonUpdated;

  /// No description provided for @errorUpdatingSeason.
  ///
  /// In en, this message translates to:
  /// **'Error updating season: {error}'**
  String errorUpdatingSeason(String error);

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @cloneSeason.
  ///
  /// In en, this message translates to:
  /// **'Clone Season'**
  String get cloneSeason;

  /// No description provided for @createNewSeason.
  ///
  /// In en, this message translates to:
  /// **'Create New Season'**
  String get createNewSeason;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDateOptional.
  ///
  /// In en, this message translates to:
  /// **'End Date (Optional)'**
  String get endDateOptional;

  /// No description provided for @noExistingTeamsToClone.
  ///
  /// In en, this message translates to:
  /// **'No existing teams to clone'**
  String get noExistingTeamsToClone;

  /// No description provided for @cloneSeasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Clone \"{seasonName}\"'**
  String cloneSeasonTitle(String seasonName);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
