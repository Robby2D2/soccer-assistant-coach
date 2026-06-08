import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:patrol/patrol.dart';
import 'package:path_provider/path_provider.dart';

import 'app_harness.dart';

/// Captures the **current on-screen frame** to a PNG inside the app's support
/// directory (`files/screenshots/<name>.png`). The CI patrol gate pulls these
/// off the emulator with `run-as`, and the qa-reviewer agent attaches them to
/// the GitHub issue so a human can see the fix before merging.
///
/// Call this from a journey test *at the moment the fixed UI is on screen* —
/// **before** any pop / navigation away. Many journey tests assert via the DB
/// after the screen pops, so the final frame is usually the wrong screen; this
/// helper lets the test deliberately snapshot the screen that demonstrates the
/// change.
///
/// ```dart
/// await $('Confirm import').tap();
/// await $.pumpAndSettle();
/// await captureScreenshot($, 'import-confirmation');   // the dialog is on screen here
/// await $('Import').tap();                             // ... then it pops
/// ```
///
/// Best-effort by design: any failure (no boundary yet, headless quirks) is
/// swallowed so a screenshot never turns a passing test red. Screenshots are a
/// review convenience, not a correctness signal.
Future<void> captureScreenshot(PatrolIntegrationTester $, String name) async {
  try {
    await $.pumpAndSettle();

    final boundary = screenshotBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      debugPrint('[captureScreenshot] no RenderRepaintBoundary for "$name" '
          '— skipping');
      return;
    }

    // Capture at the device pixel ratio so text stays legible in the artifact.
    final dpr = $.tester.view.devicePixelRatio;
    final ui.Image image = await boundary.toImage(pixelRatio: dpr);
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) {
      debugPrint('[captureScreenshot] toByteData returned null for "$name" '
          '— skipping');
      return;
    }

    final dir = await getApplicationSupportDirectory(); // /data/data/<pkg>/files
    final shotsDir = Directory('${dir.path}/screenshots');
    await shotsDir.create(recursive: true);

    final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File('${shotsDir.path}/$safe.png');
    await file.writeAsBytes(bytes.buffer.asUint8List());
    debugPrint('[captureScreenshot] wrote ${file.path} '
        '(${bytes.lengthInBytes} bytes)');
  } catch (e, st) {
    // Screenshots are best-effort; never break a passing test over one — but log
    // why so a missing artifact is debuggable from the gate output.
    debugPrint('[captureScreenshot] FAILED for "$name": $e\n$st');
  }
}
