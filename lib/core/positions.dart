const kPositions = <String>[
  'GOALIE',
  'RIGHT_DEFENSE',
  'LEFT_DEFENSE',
  'CENTER_FORWARD',
  'RIGHT_FORWARD',
  'LEFT_FORWARD',
];

/// The high-level roster categories used for filtering and the position chip.
const kPositionCategories = <String>['GK', 'DEF', 'MID', 'FWD'];

/// Map a raw position name (e.g. "RIGHT_DEFENSE", "CENTER_FORWARD") to one of
/// [kPositionCategories]. Falls back to 'MID' for anything unrecognized.
String positionCategory(String position) {
  final p = position.toUpperCase();
  if (p.contains('GOAL') || p.contains('KEEP') || p == 'GK') return 'GK';
  if (p.contains('MID')) return 'MID';
  if (p.contains('DEF') || p.contains('BACK')) return 'DEF';
  if (p.contains('FOR') ||
      p.contains('STRIK') ||
      p.contains('ATTACK') ||
      p.contains('WING')) {
    return 'FWD';
  }
  return 'MID';
}
