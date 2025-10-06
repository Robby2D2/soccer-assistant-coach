import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveTextFile(String filename, String contents) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(contents);
  return file.path;
}
