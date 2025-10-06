import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeamDetailScreen extends StatelessWidget {
  final int id;
  const TeamDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Team #$id'), actions: [
        IconButton(icon: const Icon(Icons.edit), onPressed: () => context.push('/team/$id/edit')),
      ]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(leading: const Icon(Icons.people), title: const Text('Players'), onTap: () => context.push('/team/$id/players')),
            ListTile(leading: const Icon(Icons.grid_view_rounded), title: const Text('Formations'), onTap: () => context.push('/team/$id/formations')),
            const Divider(),
            ListTile(leading: const Icon(Icons.sports_soccer), title: const Text('Games'), onTap: () => context.push('/team/$id/games')),
          ],
        ),
      ),
    );
  }
}
