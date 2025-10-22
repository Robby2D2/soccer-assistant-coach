import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Web database connection using IndexedDB
QueryExecutor createDatabaseConnection() {
  // Web database - foreign key constraints are typically less strict in IndexedDB
  return WebDatabase('soccer_manager');
}
