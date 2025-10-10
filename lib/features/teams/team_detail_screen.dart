import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

class TeamDetailScreen extends ConsumerWidget {
  final int id;
  const TeamDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Team?>(
          future: db.getTeam(id),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return Text(snapshot.data!.name);
            }
            return Text('Team #$id');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/team/$id/edit'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Players'),
              onTap: () => context.push('/team/$id/players'),
            ),
            ListTile(
              leading: const Icon(Icons.grid_view_rounded),
              title: const Text('Formations'),
              onTap: () => context.push('/team/$id/formations'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.sports_soccer),
              title: const Text('Games'),
              onTap: () => context.push('/team/$id/games'),
            ),
          ],
        ),
      ),
    );
  }
}
