import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers.dart';
import '../../widgets/standardized_app_bar_actions.dart';

class DatabaseDiagnosticScreen extends ConsumerStatefulWidget {
  const DatabaseDiagnosticScreen({super.key});

  @override
  ConsumerState<DatabaseDiagnosticScreen> createState() =>
      _DatabaseDiagnosticScreenState();
}

class _DatabaseDiagnosticScreenState
    extends ConsumerState<DatabaseDiagnosticScreen> {
  String _diagnosticResult = '';
  bool _isRunning = false;

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _diagnosticResult = 'Running diagnostics...\n';
    });

    final db = ref.read(dbProvider);
    final buffer = StringBuffer();

    try {
      // Check database version
      buffer.writeln('=== DATABASE DIAGNOSTICS ===\n');

      // List all tables
      buffer.writeln('📊 Tables in database:');
      final tables = await db.listTables();
      for (final table in tables) {
        buffer.writeln('  - $table');
      }
      buffer.writeln();

      // Check teams table structure
      buffer.writeln('🏆 Teams table structure:');
      final teamsStructure = await db.describeTeamsTable();
      if (teamsStructure.isNotEmpty) {
        for (final column in teamsStructure) {
          buffer.writeln(
            '  - ${column['name']}: ${column['type']} ${column['notnull'] == 1 ? 'NOT NULL' : 'NULL'} ${column['dflt_value'] != null ? 'DEFAULT ${column['dflt_value']}' : ''}',
          );
        }
      } else {
        buffer.writeln('  ❌ Teams table not found or inaccessible!');
      }
      buffer.writeln();

      // Check team count
      buffer.writeln('📈 Team statistics:');
      final teamCount = await db.getTeamCount();
      buffer.writeln('  Total teams: $teamCount');

      if (teamCount > 0) {
        // Try to get team details
        try {
          final teams = await db.watchTeams().first;
          buffer.writeln('  Teams found via watchTeams(): ${teams.length}');

          for (final team in teams) {
            buffer.writeln(
              '    - ID: ${team.id}, Name: "${team.name}", Archived: ${team.isArchived}',
            );
          }
        } catch (e) {
          buffer.writeln('  ❌ Error accessing teams via watchTeams(): $e');

          // Try raw SQL query
          try {
            final rawResult = await db
                .customSelect(
                  'SELECT id, name, is_archived FROM teams LIMIT 10',
                )
                .get();
            buffer.writeln('  Raw SQL query results:');
            for (final row in rawResult) {
              buffer.writeln(
                '    - ID: ${row.data['id']}, Name: "${row.data['name']}", Archived: ${row.data['is_archived']}',
              );
            }
          } catch (sqlError) {
            buffer.writeln('  ❌ Raw SQL query also failed: $sqlError');
          }
        }
      } else {
        buffer.writeln('  ℹ️ No teams found in database');
      }
      buffer.writeln();

      // Test basic database operations
      buffer.writeln('🔧 Testing database operations:');
      try {
        // Try to create a test team
        final testTeamId = await db.addTeam(
          TeamsCompanion.insert(
            name: '[DIAGNOSTIC TEST TEAM - SAFE TO DELETE]',
          ),
        );
        buffer.writeln('  ✅ Team creation: SUCCESS (ID: $testTeamId)');

        // Try to retrieve it
        final testTeam = await db.getTeam(testTeamId);
        if (testTeam != null) {
          buffer.writeln('  ✅ Team retrieval: SUCCESS');

          // Clean up test team
          await db.deleteTeam(testTeamId);
          buffer.writeln('  ✅ Team deletion: SUCCESS');
        } else {
          buffer.writeln('  ❌ Team retrieval: FAILED');
        }
      } catch (e) {
        buffer.writeln('  ❌ Database operations failed: $e');
      }

      buffer.writeln('\n=== DIAGNOSIS COMPLETE ===');
    } catch (e) {
      buffer.writeln('\n❌ CRITICAL ERROR: $e');
      buffer.writeln('\nThis suggests a serious database issue.');
    }

    setState(() {
      _diagnosticResult = buffer.toString();
      _isRunning = false;
    });
  }

  Future<void> _createTestTeam() async {
    try {
      final db = ref.read(dbProvider);
      final teamId = await db.addTeam(
        TeamsCompanion.insert(
          name: 'Test Team ${DateTime.now().millisecondsSinceEpoch}',
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created test team with ID: $teamId')),
        );
      }

      // Refresh diagnostics
      await _runDiagnostics();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create test team: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showResetDatabaseDialog() async {
    final db = ref.read(dbProvider);

    // Get data summary first
    final dataSummary = await db.getDataSummaryForReset();
    final hasData = dataSummary.values.any((count) => count > 0);

    if (!hasData) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database is already empty - no reset needed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '⚠️ DANGER: Reset Database',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This will PERMANENTLY DELETE ALL data in the database!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Data that will be lost:'),
              const SizedBox(height: 8),
              ...dataSummary.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Text(
                    '• ${entry.value} ${entry.key}',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ THIS CANNOT BE UNDONE!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Only proceed if you want to completely start over with a fresh database.',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Database'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _performDatabaseReset();
    }
  }

  Future<void> _performDatabaseReset() async {
    setState(() {
      _isRunning = true;
      _diagnosticResult = 'Resetting database...\n';
    });

    try {
      final db = ref.read(dbProvider);
      final result = await db.resetDatabaseSafely();
      final success = result['success'] as bool;
      final backupPath = result['backupPath'] as String?;

      if (success) {
        final resultMessage = StringBuffer(
          '✅ Database reset completed successfully!\n\n',
        );

        if (backupPath != null) {
          resultMessage.writeln('💾 Automatic backup created:');
          resultMessage.writeln(backupPath);
          resultMessage.writeln(
            '\nYou can restore your data using the import function if needed.',
          );
        } else {
          resultMessage.writeln('No backup was created (database was empty).');
        }

        resultMessage.writeln(
          '\nThe database is now empty and ready for fresh data.',
        );

        setState(() {
          _diagnosticResult = resultMessage.toString();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                backupPath != null
                    ? 'Database reset completed - backup saved'
                    : 'Database reset completed',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _diagnosticResult =
              '❌ Database reset failed!\n\n${result['message']}\n\nSee console for error details.';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database reset failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _diagnosticResult = '❌ Database reset error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database reset error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _exportDatabase() async {
    setState(() {
      _isRunning = true;
      _diagnosticResult = 'Exporting database...\n';
    });

    try {
      final db = ref.read(dbProvider);
      final exportPath = await db.exportDatabaseToFile();

      setState(() {
        _diagnosticResult =
            '✅ Database exported successfully!\n\nExported to: $exportPath\n\nYou can share this file or keep it as a backup.';
      });

      if (mounted) {
        // Offer to share the file
        final shouldShare = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Complete'),
            content: Text(
              'Database exported to:\n$exportPath\n\nWould you like to share this backup file?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep Local'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Share'),
              ),
            ],
          ),
        );

        if (shouldShare == true) {
          await Share.shareXFiles([
            XFile(exportPath),
          ], text: 'Soccer Assistant Coach Database Backup');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database exported successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _diagnosticResult = '❌ Database export failed!\n\nError: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  Future<void> _importDatabase() async {
    try {
      // Show warning dialog first
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text('Import Database')),
            ],
          ),
          content: const Text(
            'Importing will replace ALL current data with the data from the backup file.\n\n'
            'This action cannot be undone. Make sure you have a current backup if needed.\n\n'
            'Continue with import?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
        dialogTitle: 'Select Database Backup File',
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      setState(() {
        _isRunning = true;
        _diagnosticResult = 'Importing database...\n';
      });

      final db = ref.read(dbProvider);
      final success = await db.importDatabaseFromFile(filePath);

      if (success) {
        setState(() {
          _diagnosticResult =
              '✅ Database import completed successfully!\n\n'
              'All data has been restored from the backup file.\n'
              'You can now use the app with the imported data.';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database imported successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Refresh diagnostics to show the imported data
        await Future.delayed(const Duration(milliseconds: 500));
        await _runDiagnostics();
      } else {
        setState(() {
          _diagnosticResult =
              '❌ Database import failed!\n\n'
              'The backup file may be corrupted or incompatible.\n'
              'See console for error details.';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database import failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _diagnosticResult = '❌ Database import error!\n\nError: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Diagnostics'),
        actions: StandardizedAppBarActions.createActionsWidgets(
          [
            NavigationAction(
              label: 'Reset Database',
              icon: Icons.delete_forever,
              onPressed: _isRunning
                  ? null
                  : () {
                      _showResetDatabaseDialog();
                    },
            ),
            NavigationAction(
              label: 'Run Diagnostics',
              icon: Icons.refresh,
              onPressed: _isRunning
                  ? null
                  : () {
                      _runDiagnostics();
                    },
            ),
          ],
          additionalMenuItems: [
            NavigationAction(
              label: 'Export Database',
              icon: Icons.file_upload,
              onPressed: !_isRunning
                  ? () {
                      _exportDatabase();
                    }
                  : null,
            ),
            NavigationAction(
              label: 'Import Database',
              icon: Icons.file_download,
              onPressed: !_isRunning
                  ? () {
                      _importDatabase();
                    }
                  : null,
            ),
            NavigationAction(
              label: 'Create Test Team',
              icon: Icons.add_circle_outline,
              onPressed: !_isRunning
                  ? () {
                      _createTestTeam();
                    }
                  : null,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_isRunning) const LinearProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_diagnosticResult.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.bug_report,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Database Diagnostic Tool',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'This tool will help identify database issues and check if your teams are still in the database.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: _runDiagnostics,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Run Diagnostics'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Diagnostic Results',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SelectableText(
                                _diagnosticResult,
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
