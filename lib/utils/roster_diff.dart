import '../data/db/database.dart';

class RosterDiff {
  final List<Map<String, String>> toAdd;
  final List<({Player existing, Map<String, String> csvRow})> toUpdate;
  final List<Player> toArchive;

  const RosterDiff({
    required this.toAdd,
    required this.toUpdate,
    required this.toArchive,
  });

  bool get hasChanges =>
      toAdd.isNotEmpty || toUpdate.isNotEmpty || toArchive.isNotEmpty;
}

RosterDiff diffRoster(
  List<Player> existing,
  List<Map<String, String>> csvRows,
) {
  final existingByName = <String, Player>{};
  for (final p in existing) {
    existingByName[_key(p.firstName, p.lastName)] = p;
  }

  final csvKeys = <String>{};
  final toAdd = <Map<String, String>>[];
  final toUpdate = <({Player existing, Map<String, String> csvRow})>[];

  for (final row in csvRows) {
    final key = _key(row['firstName'] ?? '', row['lastName'] ?? '');
    csvKeys.add(key);
    final match = existingByName[key];
    if (match == null) {
      toAdd.add(row);
    } else {
      final csvJersey = int.tryParse(row['jerseyNumber']?.trim() ?? '');
      if (match.jerseyNumber != csvJersey || !match.isPresent) {
        toUpdate.add((existing: match, csvRow: row));
      }
    }
  }

  final toArchive = existing
      .where(
        (p) => p.isPresent && !csvKeys.contains(_key(p.firstName, p.lastName)),
      )
      .toList();

  return RosterDiff(toAdd: toAdd, toUpdate: toUpdate, toArchive: toArchive);
}

String _key(String first, String last) =>
    '${first.trim().toLowerCase()}|${last.trim().toLowerCase()}';
