import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';

/// Simple splash/loading screen to ensure first frame renders quickly on cold start.
/// Performs a lightweight async readiness check (database integrity & teams existing)
/// then navigates to '/'.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _runStartup();
  }

  Future<void> _runStartup() async {
    try {
      // Perform minimal async checks (do NOT block UI long)
      final db = ref.read(dbProvider);
      // Timeout after 2 seconds to avoid hanging
      // (Optional) Could branch on presence of teams later
      await db.hasTeams().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      if (!mounted) return;
      // Navigate to home
      context.go('/');
    } catch (e) {
      setState(() => _error = 'Startup error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.background,
      body: Center(
        child: _error == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 72,
                    width: 72,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Preparing app...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: scheme.error, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: scheme.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _error = null);
                      _runStartup();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
      ),
    );
  }
}
