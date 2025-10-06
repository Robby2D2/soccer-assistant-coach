import 'dart:convert';

String _escape(String f) {
  final s = f.replaceAll('"', '""');
  if (s.contains(',') || s.contains('\n') || s.contains('"')) { return '"$s"'; }
  return s;
}
String toCsvRow(Iterable<String> fields) => fields.map(_escape).join(',');

String playersToCsv(List<Map<String, String>> rows) {
  final buffer = StringBuffer();
  buffer.writeln('firstName,lastName,isPresent');
  for (final r in rows) {
    buffer.writeln(toCsvRow([r['firstName'] ?? '', r['lastName'] ?? '', r['isPresent'] ?? 'true']));
  }
  return buffer.toString();
}
List<Map<String, String>> csvToPlayers(String csv) {
  final lines = const LineSplitter().convert(csv.trim());
  if (lines.isEmpty) return [];
  final out = <Map<String,String>>[];
  for (var i = 1; i < lines.length; i++) {
    final row = _parseCsvLine(lines[i]);
    if (row.isEmpty) continue;
    final fn = row.isNotEmpty ? row[0] : '';
    final ln = row.length > 1 ? row[1] : '';
    final ip = row.length > 2 ? row[2].toLowerCase() : 'true';
    if (fn.isEmpty && ln.isEmpty) continue;
    out.add({'firstName': fn, 'lastName': ln, 'isPresent': ip == 'true' ? 'true' : 'false'});
  }
  return out;
}
List<String> _parseCsvLine(String line) {
  final out = <String>[];
  final sb = StringBuffer();
  bool inQuotes = false;
  for (int i=0; i<line.length; i++) {
    final c = line[i];
    if (inQuotes) {
      if (c == '"') {
        if (i+1 < line.length && line[i+1] == '"') { sb.write('"'); i++; } else { inQuotes = false; }
      } else { sb.write(c); }
    } else {
      if (c == '"') { inQuotes = true; }
      else if (c == ',') { out.add(sb.toString()); sb.clear(); }
      else { sb.write(c); }
    }
  }
  out.add(sb.toString());
  return out;
}
