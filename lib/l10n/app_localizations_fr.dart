// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Entraîneur Assistant de Football';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsVibration => 'Vibration d\'Alarme';

  @override
  String get settingsVibrationDescription =>
      'Faire vibrer l\'appareil lorsque l\'alarme de période se déclenche';

  @override
  String get settingsNotifications => 'Notifications et Alarmes';

  @override
  String get permissionNotificationsTitle => 'Autoriser les Notifications';

  @override
  String get permissionNotificationsDescription =>
      'Activer les alarmes de période et les minuteurs de jeu pour vous alerter même lorsque l\'application est fermée.';

  @override
  String get permissionExactAlarmTitle => 'Alarmes Exactes';

  @override
  String get permissionExactAlarmDescription =>
      'Accorder la permission d\'alarme exacte pour que les alarmes de période se déclenchent à la seconde précise (Android 12+).';

  @override
  String get permissionRequestButton => 'Demander les Permissions';

  @override
  String get permissionGranted => 'Permission Accordée';

  @override
  String get permissionDenied => 'Permission Refusée';

  @override
  String get vibrationEnabledStatus => 'Vibration activée';

  @override
  String get vibrationDisabledStatus => 'Vibration désactivée';

  @override
  String get stopAlarmAction => 'Arrêter l\'Alarme';

  @override
  String get alarmDismissed => 'Alarme ignorée';

  @override
  String get alarmDismissedBody => 'Compte à rebours en cours…';

  @override
  String get alarmCustomization => 'Personnalisation des Alarmes';

  @override
  String get shiftAlarmsEnabled => 'Alarmes de Fin de Période';

  @override
  String get shiftAlarmsDescription =>
      'Jouer l\'alarme lorsque le temps de période expire';

  @override
  String get halftimeAlarmsEnabled => 'Alarmes de Mi-temps';

  @override
  String get halftimeAlarmsDescription =>
      'Jouer l\'alarme à la mi-temps dans les jeux traditionnels';

  @override
  String get alarmSounds => 'Sons d\'Alarme';

  @override
  String get shiftAlarmSound => 'Son de Fin de Période';

  @override
  String get halftimeAlarmSound => 'Son de Mi-temps';

  @override
  String get alarmVolume => 'Volume';

  @override
  String get alarmDuration => 'Durée d\'Alarme';

  @override
  String get alarmDurationDescription =>
      'Combien de temps les alarmes sonnent avant de s\'arrêter';

  @override
  String get previewSound => 'Aperçu';

  @override
  String get seconds => 'secondes';

  @override
  String get language => 'Langue';

  @override
  String get languageDescription => 'Sélectionner la langue de l\'application';

  @override
  String get home => 'Accueil';

  @override
  String get settings => 'Paramètres';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Arrêt';

  @override
  String get create => 'Créer';

  @override
  String get done => 'Terminé';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get teams => 'Équipes';

  @override
  String get createTeam => 'Créer une Équipe';

  @override
  String get teamName => 'Nom de l\'équipe';

  @override
  String get manageTeams => 'Gérer les Équipes';

  @override
  String get manageSeasons => 'Gérer les saisons';

  @override
  String get noActiveSeasons => 'Aucune Saison Active';

  @override
  String get createSeason => 'Créer une Saison';

  @override
  String get archived => 'Archivé';

  @override
  String get traditional => 'Traditionnel';

  @override
  String get shiftMode => 'Mode Périodes';

  @override
  String get showArchived => 'Afficher Archivés';

  @override
  String get hideArchived => 'Masquer archivés';

  @override
  String get archive => 'Archiver';

  @override
  String get restore => 'Restaurer';

  @override
  String get exportCsv => 'Exporter CSV';

  @override
  String get inputMetrics => 'Saisir les Métriques';

  @override
  String get viewMetrics => 'Voir les Métriques';

  @override
  String get attendance => 'Présence';

  @override
  String get formation => 'Formation';

  @override
  String get endGame => 'Terminer le Match';

  @override
  String get databaseDiagnostics => 'Diagnostics de base de données';

  @override
  String get noArchivedTeams => 'Aucune équipe archivée';

  @override
  String get noTeamsYet => 'Aucune équipe encore';

  @override
  String get noArchivedTeamsDescription =>
      'Vous n\'avez aucune équipe archivée.';

  @override
  String get noTeamsYetDescription =>
      'Créez votre première équipe pour commencer à gérer les joueurs, formations et jeux.';

  @override
  String get noActiveSeasonFound =>
      'Aucune saison active trouvée. Veuillez d\'abord créer une saison.';

  @override
  String creatingTeamFor(String seasonName) {
    return 'Création d\'équipe pour : $seasonName';
  }

  @override
  String get noActiveSeason => 'Aucune saison active';

  @override
  String get createSeasonToManageTeams =>
      'Créez une saison pour commencer à gérer les équipes.';

  @override
  String errorLoadingTeams(String error) {
    return 'Erreur lors du chargement des équipes : $error';
  }

  @override
  String get restoreTeam => 'Restaurer l\'équipe';

  @override
  String get archiveTeam => 'Archiver l\'équipe';

  @override
  String get editTeam => 'Modifier l\'équipe';

  @override
  String errorLoadingSeason(String error) {
    return 'Erreur lors du chargement de la saison : $error';
  }

  @override
  String get games => 'Jeux';

  @override
  String get createGame => 'Créer un jeu';

  @override
  String get win => 'Victoire';

  @override
  String get loss => 'Défaite';

  @override
  String get draw => 'Match nul';

  @override
  String get noArchivedGames => 'Aucun jeu archivé';

  @override
  String get noGamesYet => 'Aucun jeu encore';

  @override
  String get noArchivedGamesDescription => 'Vous n\'avez aucun jeu archivé.';

  @override
  String get noGamesYetDescription =>
      'Programmez votre premier jeu pour commencer à suivre les performances des matchs et les statistiques des joueurs.';

  @override
  String get startGame => 'Commencer le jeu';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Reprendre';

  @override
  String get start => 'Commencer';

  @override
  String get firstHalf => '1ère Mi-temps';

  @override
  String get secondHalf => '2ème Mi-temps';

  @override
  String get halftime => 'Mi-temps';

  @override
  String get overtime => 'Prolongations';

  @override
  String get completeGame => 'Terminer le Match';

  @override
  String get completing => 'Finalisation...';

  @override
  String get players => 'Joueurs';

  @override
  String get noPlayersYet => 'Aucun joueur encore';

  @override
  String get addPlayersDescription =>
      'Ajoutez des joueurs à l\'effectif de votre équipe pour commencer la gestion des alignements.';

  @override
  String get addPlayer => 'Ajouter joueur';

  @override
  String get importCsv => 'Importer CSV';

  @override
  String get newPlayer => 'Nouveau';

  @override
  String get player => 'Joueur';

  @override
  String get formations => 'Formations';

  @override
  String get createFormation => 'Créer une Formation';

  @override
  String get metrics => 'Métriques';

  @override
  String get resetToDefaults => 'Réinitialiser aux Valeurs par Défaut';

  @override
  String get resetSettings => 'Réinitialiser les Paramètres';

  @override
  String get resetConfirmation =>
      'Êtes-vous sûr de vouloir réinitialiser tous les paramètres d\'alarme à leurs valeurs par défaut ? Cette action ne peut pas être annulée.';

  @override
  String get settingsResetToDefaults =>
      'Paramètres réinitialisés aux valeurs par défaut';

  @override
  String get currentConfiguration => 'Configuration Actuelle';

  @override
  String get enabled => 'Activé';

  @override
  String get disabled => 'Désactivé';

  @override
  String get on => 'Activé';

  @override
  String get off => 'Désactivé';

  @override
  String get runDiagnostics => 'Exécuter les diagnostics';

  @override
  String get exportDatabase => 'Exporter la base de données';

  @override
  String get importDatabase => 'Importer la base de données';

  @override
  String get resetDatabase => 'Réinitialiser la base de données';

  @override
  String get diagnosticResults => 'Résultats du diagnostic';

  @override
  String get databaseDiagnosticTool => 'Outil de diagnostic de base de données';

  @override
  String get databaseDiagnosticDescription =>
      'Cet outil aidera à identifier les problèmes de base de données et vérifier si vos équipes sont toujours dans la base de données.';

  @override
  String get createTestTeam => 'Créer équipe de test';

  @override
  String get runningDiagnostics => 'Exécution des diagnostics...';

  @override
  String get databaseExported => 'Base de données exportée avec succès';

  @override
  String get databaseImported => 'Base de données importée avec succès';

  @override
  String get exportFailed => 'Échec de l\'exportation';

  @override
  String get importFailed => 'Échec de l\'importation';

  @override
  String get cannotBeUndone => 'CECI NE PEUT PAS ÊTRE ANNULÉ !';

  @override
  String get startOverWarning =>
      'Ne procédez que si vous voulez recommencer complètement avec une base de données fraîche.';

  @override
  String get teamLogo => 'Logo de l\'Équipe';

  @override
  String get selectTeamLogo => 'Sélectionner le Logo de l\'Équipe';

  @override
  String get chooseFromGallery => 'Choisir dans la Galerie';

  @override
  String get takePhoto => 'Prendre une Photo';

  @override
  String get teamColorPalette => 'Palette de couleurs de l\'équipe';

  @override
  String get pickColor => 'Choisir la couleur';

  @override
  String get advancedPicker => 'Sélecteur avancé';

  @override
  String get color => 'Couleur';

  @override
  String get teamManagementHub => 'Centre de gestion d\'équipe';

  @override
  String get teamManagement => 'Gestion d\'équipe';

  @override
  String get gameManagement => 'Gestion des matchs';

  @override
  String get manageTeamRosterDescription =>
      'Gérer l\'effectif de l\'équipe et le statut des joueurs';

  @override
  String get setupTacticalFormationsDescription =>
      'Configurer les formations tactiques et les positions';

  @override
  String get scheduleGamesDescription =>
      'Programmer les matchs et suivre l\'historique des matchs';

  @override
  String get viewPlayerStatisticsDescription =>
      'Voir les statistiques et performances de tous les temps des joueurs';

  @override
  String get teamMetrics => 'Métriques de l\'équipe';

  @override
  String get activeGames => 'Matchs actifs';

  @override
  String get noActiveGames => 'Aucun match actif';

  @override
  String get startGameForQuickAccess =>
      'Démarrez un match pour le voir ici pour un accès rapide';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String errorWithDetails(String error) {
    return 'Erreur : $error';
  }

  @override
  String get languageChangedTo => 'Langue changée pour';

  @override
  String get close => 'Fermer';

  @override
  String get noFormationsYet => 'Aucune Formation Encore';

  @override
  String get noFormationsYetDescription =>
      'Créez des formations tactiques pour organiser le positionnement et la stratégie de votre équipe.';

  @override
  String get createFormationTooltip => 'Créer une formation';

  @override
  String get editFormation => 'Modifier la Formation';

  @override
  String get deleteFormation => 'Supprimer la Formation';

  @override
  String get deleteFormationTitle => 'Supprimer la formation ?';

  @override
  String deleteFormationMessage(String formationName) {
    return 'Supprimer \"$formationName\" ?';
  }

  @override
  String playersCount(int count) {
    return '$count joueurs';
  }

  @override
  String get noDate => 'Aucune date';

  @override
  String get opponent => 'Adversaire';

  @override
  String get pickDateTime => 'Choisir date/heure';

  @override
  String get noFormation => 'Aucune formation';

  @override
  String get manageFormations => 'Gérer les formations';

  @override
  String get manageFormationsTooltip => 'Gérer les formations';

  @override
  String get noPlayersFoundForTeam => 'Aucun joueur trouvé pour cette équipe.';

  @override
  String playerIdLabel(int playerId) {
    return 'ID du Joueur : $playerId';
  }

  @override
  String get manage => 'Gérer';

  @override
  String get selectMetricType => 'Sélectionner le Type de Métrique';

  @override
  String get quickEntry => 'Saisie Rapide';

  @override
  String get viewOverview => 'Voir l\'Aperçu';

  @override
  String addedMetric(String metric) {
    return 'Ajouté $metric';
  }

  @override
  String removedMetric(String metric) {
    return 'Retiré $metric';
  }

  @override
  String quickMetricEntry(String metric) {
    return 'Saisie Rapide de $metric';
  }

  @override
  String tapPlayersWhoScored(String metric) {
    return 'Touchez les joueurs qui ont marqué des ${metric}s :';
  }

  @override
  String get apply => 'Appliquer';

  @override
  String addedMultipleMetrics(int count, String metric) {
    return 'Ajouté $count ${metric}s';
  }

  @override
  String get goal => 'But';

  @override
  String get assist => 'Passe décisive';

  @override
  String get importRosterCsv => 'Importer CSV d\'Effectif';

  @override
  String get pasteCsvWithHeader =>
      'Coller CSV avec en-tête : firstName,lastName,jerseyNumber (le numéro de maillot est optionnel)';

  @override
  String get csvHintText =>
      'firstName,lastName,jerseyNumber\nJane,Doe,10\nJohn,Smith,\nAlex,Johnson,7';

  @override
  String previewRows(int count) {
    return 'Aperçu : $count lignes';
  }

  @override
  String jerseyNumber(String number) {
    return 'Maillot #: $number';
  }

  @override
  String get jerseyNA => 'N/A';

  @override
  String get import => 'Importer';

  @override
  String get creatingSeason => 'Création de la saison...';

  @override
  String get seasonCreatedSuccessfully => 'Saison créée avec succès !';

  @override
  String errorCreatingSeason(String error) {
    return 'Erreur lors de la création de la saison : $error';
  }

  @override
  String get cloningSeason => 'Clonage de la saison...';

  @override
  String get seasonClonedSuccessfully => 'Saison clonée avec succès !';

  @override
  String errorCloningSeason(String error) {
    return 'Erreur lors du clonage de la saison : $error';
  }

  @override
  String get seasonActivated => 'Saison activée !';

  @override
  String errorActivatingSeason(String error) {
    return 'Erreur lors de l\'activation de la saison : $error';
  }

  @override
  String get archiveSeason => 'Archiver la Saison';

  @override
  String get seasonArchived => 'Saison archivée !';

  @override
  String errorArchivingSeason(String error) {
    return 'Erreur lors de l\'archivage de la saison : $error';
  }

  @override
  String get seasonUpdated => 'Saison mise à jour !';

  @override
  String errorUpdatingSeason(String error) {
    return 'Erreur lors de la mise à jour de la saison : $error';
  }

  @override
  String get activate => 'Activer';

  @override
  String get cloneSeason => 'Cloner la Saison';

  @override
  String get createNewSeason => 'Créer une Nouvelle Saison';

  @override
  String get startDate => 'Date de Début';

  @override
  String get endDateOptional => 'Date de Fin (Optionnel)';

  @override
  String get noExistingTeamsToClone => 'Aucune équipe existante à cloner';

  @override
  String cloneSeasonTitle(String seasonName) {
    return 'Cloner \"$seasonName\"';
  }
}
