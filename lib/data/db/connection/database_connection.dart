import 'package:drift/drift.dart';

/// Platform-specific database connection
/// This file will be replaced by platform-specific implementations
QueryExecutor createDatabaseConnection() {
  throw UnsupportedError('Database connection not configured for this platform');
}