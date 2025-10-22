import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Web database connection using IndexedDB
QueryExecutor createDatabaseConnection() {
  return WebDatabase('soccer_manager');
}