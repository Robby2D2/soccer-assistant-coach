// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Entrenador Asistente de Fútbol';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsVibration => 'Vibración de Alarma';

  @override
  String get settingsVibrationDescription =>
      'Vibrar el dispositivo cuando se active la alarma de turno';

  @override
  String get settingsNotifications => 'Notificaciones y Alarmas';

  @override
  String get permissionNotificationsTitle => 'Permitir Notificaciones';

  @override
  String get permissionNotificationsDescription =>
      'Habilitar alarmas de turno y temporizadores de juego para alertarte incluso cuando la aplicación está cerrada.';

  @override
  String get permissionExactAlarmTitle => 'Alarmas Exactas';

  @override
  String get permissionExactAlarmDescription =>
      'Otorgar permiso de alarma exacta para que las alarmas de turno se activen en el segundo preciso (Android 12+).';

  @override
  String get permissionRequestButton => 'Solicitar Permisos';

  @override
  String get permissionGranted => 'Permiso Otorgado';

  @override
  String get permissionDenied => 'Permiso Denegado';

  @override
  String get vibrationEnabledStatus => 'Vibración activada';

  @override
  String get vibrationDisabledStatus => 'Vibración desactivada';

  @override
  String get stopAlarmAction => 'Detener Alarma';

  @override
  String get alarmDismissed => 'Alarma descartada';

  @override
  String get alarmDismissedBody => 'Cuenta regresiva continuando…';

  @override
  String get alarmCustomization => 'Personalización de Alarmas';

  @override
  String get shiftAlarmsEnabled => 'Alarmas de Fin de Turno';

  @override
  String get shiftAlarmsDescription =>
      'Reproducir alarma cuando expire el tiempo del turno';

  @override
  String get halftimeAlarmsEnabled => 'Alarmas de Medio Tiempo';

  @override
  String get halftimeAlarmsDescription =>
      'Reproducir alarma en el medio tiempo en juegos tradicionales';

  @override
  String get alarmSounds => 'Sonidos de Alarma';

  @override
  String get shiftAlarmSound => 'Sonido de Fin de Turno';

  @override
  String get halftimeAlarmSound => 'Sonido de Medio Tiempo';

  @override
  String get alarmVolume => 'Volumen';

  @override
  String get alarmDuration => 'Duración de Alarma';

  @override
  String get alarmDurationDescription =>
      'Cuánto tiempo suenan las alarmas antes de detenerse';

  @override
  String get previewSound => 'Vista Previa';

  @override
  String get seconds => 'segundos';

  @override
  String get language => 'Idioma';

  @override
  String get languageDescription => 'Seleccionar el idioma de la aplicación';

  @override
  String get home => 'Inicio';

  @override
  String get settings => 'Configuración';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Eliminar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Parada';

  @override
  String get create => 'Crear';

  @override
  String get done => 'Hecho';

  @override
  String get reset => 'Reiniciar';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get teams => 'Equipos';

  @override
  String get createTeam => 'Crear Equipo';

  @override
  String get teamName => 'Nombre del equipo';

  @override
  String get manageTeams => 'Gestionar Equipos';

  @override
  String get manageSeasons => 'Gestionar temporadas';

  @override
  String get noActiveSeasons => 'Sin Temporada Activa';

  @override
  String get createSeason => 'Crear Temporada';

  @override
  String get archived => 'Archivado';

  @override
  String get traditional => 'Tradicional';

  @override
  String get shiftMode => 'Modo de Turnos';

  @override
  String get showArchived => 'Mostrar Archivados';

  @override
  String get hideArchived => 'Ocultar archivados';

  @override
  String get archive => 'Archivar';

  @override
  String get restore => 'Restaurar';

  @override
  String get exportCsv => 'Exportar CSV';

  @override
  String get inputMetrics => 'Ingresar Métricas';

  @override
  String get viewMetrics => 'Ver Métricas';

  @override
  String get attendance => 'Asistencia';

  @override
  String get formation => 'Formación';

  @override
  String get endGame => 'Finalizar Juego';

  @override
  String get databaseDiagnostics => 'Diagnósticos de base de datos';

  @override
  String get noArchivedTeams => 'No hay equipos archivados';

  @override
  String get noTeamsYet => 'Aún no hay equipos';

  @override
  String get noArchivedTeamsDescription => 'No tienes equipos archivados.';

  @override
  String get noTeamsYetDescription =>
      'Crea tu primer equipo para comenzar a gestionar jugadores, formaciones y juegos.';

  @override
  String get noActiveSeasonFound =>
      'No se encontró temporada activa. Por favor, crea una temporada primero.';

  @override
  String creatingTeamFor(String seasonName) {
    return 'Creando equipo para: $seasonName';
  }

  @override
  String get noActiveSeason => 'Sin temporada activa';

  @override
  String get createSeasonToManageTeams =>
      'Crea una temporada para comenzar a gestionar equipos.';

  @override
  String errorLoadingTeams(String error) {
    return 'Error cargando equipos: $error';
  }

  @override
  String get restoreTeam => 'Restaurar equipo';

  @override
  String get archiveTeam => 'Archivar equipo';

  @override
  String get editTeam => 'Editar equipo';

  @override
  String errorLoadingSeason(String error) {
    return 'Error cargando temporada: $error';
  }

  @override
  String get games => 'Juegos';

  @override
  String get createGame => 'Crear juego';

  @override
  String get win => 'Victoria';

  @override
  String get loss => 'Derrota';

  @override
  String get draw => 'Empate';

  @override
  String get noArchivedGames => 'No hay juegos archivados';

  @override
  String get noGamesYet => 'Aún no hay juegos';

  @override
  String get noArchivedGamesDescription => 'No tienes juegos archivados.';

  @override
  String get noGamesYetDescription =>
      'Programa tu primer juego para comenzar a rastrear el rendimiento del partido y las estadísticas de los jugadores.';

  @override
  String get startGame => 'Iniciar juego';

  @override
  String get pause => 'Pausar';

  @override
  String get resume => 'Reanudar';

  @override
  String get start => 'Iniciar';

  @override
  String get firstHalf => '1er Tiempo';

  @override
  String get secondHalf => '2do Tiempo';

  @override
  String get halftime => 'Medio Tiempo';

  @override
  String get overtime => 'Tiempo Extra';

  @override
  String get completeGame => 'Completar Juego';

  @override
  String get completing => 'Completando...';

  @override
  String get players => 'Jugadores';

  @override
  String get noPlayersYet => 'Aún no hay jugadores';

  @override
  String get addPlayersDescription =>
      'Agrega jugadores a la plantilla de tu equipo para comenzar con la gestión de alineaciones.';

  @override
  String get addPlayer => 'Agregar jugador';

  @override
  String get importCsv => 'Importar CSV';

  @override
  String get newPlayer => 'Nuevo';

  @override
  String get player => 'Jugador';

  @override
  String get formations => 'Formaciones';

  @override
  String get createFormation => 'Crear Formación';

  @override
  String get metrics => 'Métricas';

  @override
  String get resetToDefaults => 'Restablecer a Valores Predeterminados';

  @override
  String get resetSettings => 'Restablecer Configuración';

  @override
  String get resetConfirmation =>
      '¿Estás seguro de que quieres restablecer todas las configuraciones de alarma a sus valores predeterminados? Esta acción no se puede deshacer.';

  @override
  String get settingsResetToDefaults =>
      'Configuración restablecida a valores predeterminados';

  @override
  String get currentConfiguration => 'Configuración Actual';

  @override
  String get enabled => 'Habilitado';

  @override
  String get disabled => 'Deshabilitado';

  @override
  String get on => 'Encendido';

  @override
  String get off => 'Apagado';

  @override
  String get runDiagnostics => 'Ejecutar diagnósticos';

  @override
  String get exportDatabase => 'Exportar base de datos';

  @override
  String get importDatabase => 'Importar base de datos';

  @override
  String get resetDatabase => 'Restablecer base de datos';

  @override
  String get diagnosticResults => 'Resultados del diagnóstico';

  @override
  String get databaseDiagnosticTool =>
      'Herramienta de diagnóstico de base de datos';

  @override
  String get databaseDiagnosticDescription =>
      'Esta herramienta ayudará a identificar problemas de la base de datos y verificar si tus equipos siguen en la base de datos.';

  @override
  String get createTestTeam => 'Crear equipo de prueba';

  @override
  String get runningDiagnostics => 'Ejecutando diagnósticos...';

  @override
  String get databaseExported => 'Base de datos exportada exitosamente';

  @override
  String get databaseImported => 'Base de datos importada exitosamente';

  @override
  String get exportFailed => 'Exportación falló';

  @override
  String get importFailed => 'Importación falló';

  @override
  String get cannotBeUndone => '¡ESTO NO SE PUEDE DESHACER!';

  @override
  String get startOverWarning =>
      'Solo procede si quieres empezar completamente de nuevo con una base de datos fresca.';

  @override
  String get teamLogo => 'Logo del Equipo';

  @override
  String get selectTeamLogo => 'Seleccionar Logo del Equipo';

  @override
  String get chooseFromGallery => 'Elegir de la Galería';

  @override
  String get takePhoto => 'Tomar Foto';

  @override
  String get teamColorPalette => 'Paleta de colores del equipo';

  @override
  String get pickColor => 'Elegir color';

  @override
  String get advancedPicker => 'Selector avanzado';

  @override
  String get color => 'Color';

  @override
  String get teamManagementHub => 'Centro de gestión del equipo';

  @override
  String get teamManagement => 'Gestión del equipo';

  @override
  String get gameManagement => 'Gestión de juegos';

  @override
  String get manageTeamRosterDescription =>
      'Gestionar plantilla del equipo y estado de jugadores';

  @override
  String get setupTacticalFormationsDescription =>
      'Configurar formaciones tácticas y posiciones';

  @override
  String get scheduleGamesDescription =>
      'Programar juegos y seguir historial de partidos';

  @override
  String get viewPlayerStatisticsDescription =>
      'Ver estadísticas y rendimiento de jugadores de todos los tiempos';

  @override
  String get teamMetrics => 'Métricas del equipo';

  @override
  String get activeGames => 'Juegos activos';

  @override
  String get noActiveGames => 'No hay juegos activos';

  @override
  String get startGameForQuickAccess =>
      'Inicia un juego para verlo aquí y acceder rápidamente';

  @override
  String get quickActions => 'Acciones rápidas';

  @override
  String errorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String get languageChangedTo => 'Idioma cambiado a';

  @override
  String get close => 'Cerrar';

  @override
  String get noFormationsYet => 'Aún No Hay Formaciones';

  @override
  String get noFormationsYetDescription =>
      'Crea formaciones tácticas para organizar el posicionamiento y la estrategia de tu equipo.';

  @override
  String get createFormationTooltip => 'Crear formación';

  @override
  String get editFormation => 'Editar Formación';

  @override
  String get deleteFormation => 'Eliminar Formación';

  @override
  String get deleteFormationTitle => '¿Eliminar formación?';

  @override
  String deleteFormationMessage(String formationName) {
    return '¿Eliminar \"$formationName\"?';
  }

  @override
  String playersCount(int count) {
    return '$count jugadores';
  }

  @override
  String get noDate => 'Sin fecha';

  @override
  String get opponent => 'Oponente';

  @override
  String get pickDateTime => 'Elegir fecha/hora';

  @override
  String get noFormation => 'Sin formación';

  @override
  String get manageFormations => 'Gestionar formaciones';

  @override
  String get manageFormationsTooltip => 'Gestionar formaciones';

  @override
  String get noPlayersFoundForTeam =>
      'No se encontraron jugadores para este equipo.';

  @override
  String playerIdLabel(int playerId) {
    return 'ID del Jugador: $playerId';
  }

  @override
  String get manage => 'Gestionar';

  @override
  String get selectMetricType => 'Seleccionar Tipo de Métrica';

  @override
  String get quickEntry => 'Entrada Rápida';

  @override
  String get viewOverview => 'Ver Resumen';

  @override
  String addedMetric(String metric) {
    return 'Agregado $metric';
  }

  @override
  String removedMetric(String metric) {
    return 'Eliminado $metric';
  }

  @override
  String quickMetricEntry(String metric) {
    return 'Entrada Rápida de $metric';
  }

  @override
  String tapPlayersWhoScored(String metric) {
    return 'Toca los jugadores que anotaron ${metric}s:';
  }

  @override
  String get apply => 'Aplicar';

  @override
  String addedMultipleMetrics(int count, String metric) {
    return 'Agregados $count ${metric}s';
  }

  @override
  String get goal => 'Gol';

  @override
  String get assist => 'Asistencia';

  @override
  String get importRosterCsv => 'Importar CSV de Plantilla';

  @override
  String get pasteCsvWithHeader =>
      'Pegar CSV con encabezado: firstName,lastName,jerseyNumber (el número de camiseta es opcional)';

  @override
  String get csvHintText =>
      'firstName,lastName,jerseyNumber\nJane,Doe,10\nJohn,Smith,\nAlex,Johnson,7';

  @override
  String previewRows(int count) {
    return 'Vista previa: $count filas';
  }

  @override
  String jerseyNumber(String number) {
    return 'Camiseta #: $number';
  }

  @override
  String get jerseyNA => 'N/A';

  @override
  String get import => 'Importar';

  @override
  String get creatingSeason => 'Creando temporada...';

  @override
  String get seasonCreatedSuccessfully => '¡Temporada creada exitosamente!';

  @override
  String errorCreatingSeason(String error) {
    return 'Error creando temporada: $error';
  }

  @override
  String get cloningSeason => 'Clonando temporada...';

  @override
  String get seasonClonedSuccessfully => '¡Temporada clonada exitosamente!';

  @override
  String errorCloningSeason(String error) {
    return 'Error clonando temporada: $error';
  }

  @override
  String get seasonActivated => '¡Temporada activada!';

  @override
  String errorActivatingSeason(String error) {
    return 'Error activando temporada: $error';
  }

  @override
  String get archiveSeason => 'Archivar Temporada';

  @override
  String get seasonArchived => '¡Temporada archivada!';

  @override
  String errorArchivingSeason(String error) {
    return 'Error archivando temporada: $error';
  }

  @override
  String get seasonUpdated => '¡Temporada actualizada!';

  @override
  String errorUpdatingSeason(String error) {
    return 'Error actualizando temporada: $error';
  }

  @override
  String get activate => 'Activar';

  @override
  String get cloneSeason => 'Clonar Temporada';

  @override
  String get createNewSeason => 'Crear Nueva Temporada';

  @override
  String get startDate => 'Fecha de Inicio';

  @override
  String get endDateOptional => 'Fecha de Fin (Opcional)';

  @override
  String get noExistingTeamsToClone => 'No hay equipos existentes para clonar';

  @override
  String cloneSeasonTitle(String seasonName) {
    return 'Clonar \"$seasonName\"';
  }
}
