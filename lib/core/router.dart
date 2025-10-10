import 'package:go_router/go_router.dart';
import '../features/teams/teams_screen.dart';
import '../features/teams/team_detail_screen.dart';
import '../features/teams/team_edit_screen.dart';
import '../features/players/players_screen.dart';
import '../features/players/player_edit_screen.dart';
import '../features/players/roster_import_screen.dart';
import '../features/games/games_screen.dart';
import '../features/games/smart_game_screen.dart';
import '../features/games/game_edit_screen.dart';
import '../features/games/assign_players_screen.dart';
import '../features/games/metrics_overview_screen.dart';
import '../features/games/metrics_input_screen.dart';
import '../features/formations/team_formations_screen.dart';
import '../features/formations/formation_edit_screen.dart';
import '../features/games/formation_selection_screen.dart';
import '../features/games/attendance_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const TeamsScreen()),
    GoRoute(
      path: '/team/:id',
      builder: (_, s) =>
          TeamDetailScreen(id: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/team/:id/edit',
      builder: (_, s) =>
          TeamEditScreen(teamId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/team/:id/players',
      builder: (_, s) =>
          PlayersScreen(teamId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/team/:id/formations',
      builder: (_, s) =>
          TeamFormationsScreen(teamId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/team/:id/formations/new',
      builder: (_, s) =>
          FormationEditScreen(teamId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/team/:id/formations/:fid/edit',
      builder: (_, s) => FormationEditScreen(
        teamId: int.parse(s.pathParameters['id']!),
        formationId: int.parse(s.pathParameters['fid']!),
      ),
    ),
    GoRoute(
      path: '/team/:id/players/import',
      builder: (_, s) =>
          RosterImportScreen(teamId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/player/:id/edit',
      builder: (_, s) =>
          PlayerEditScreen(playerId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/team/:id/games',
      builder: (_, s) =>
          GamesScreen(teamId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/game/:id',
      builder: (_, s) =>
          SmartGameScreen(gameId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/game/:id/edit',
      builder: (_, s) => GameEditScreen(
        gameId: int.parse(s.pathParameters['id']!),
        basicOnly: s.uri.queryParameters['basic'] == 'true',
      ),
    ),
    GoRoute(
      path: '/game/:id/assign/:shiftId',
      builder: (_, s) => AssignPlayersScreen(
        gameId: int.parse(s.pathParameters['id']!),
        shiftId: int.parse(s.pathParameters['shiftId']!),
      ),
    ),
    GoRoute(
      path: '/game/:id/metrics',
      builder: (_, s) =>
          MetricsOverviewScreen(gameId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/game/:id/metrics/input',
      builder: (_, s) =>
          MetricsInputScreen(gameId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/game/:id/formation',
      builder: (_, s) =>
          FormationSelectionScreen(gameId: int.parse(s.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/game/:id/attendance',
      builder: (_, s) =>
          AttendanceScreen(gameId: int.parse(s.pathParameters['id']!)),
    ),
  ],
);
