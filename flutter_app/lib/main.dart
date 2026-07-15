import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

/// Phone-like dimensions for desktop windows — roughly a large modern phone
/// screen (e.g. an iPhone 14 Pro Max / Pixel-class device) so the app reads
/// as "a mobile screen" rather than a freely resizable desktop window.
const _desktopWindowSize = Size(430, 900);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // window_manager only applies to Windows/macOS/Linux builds — calling its
  // APIs on Android/iOS/web would throw, so this whole block is skipped
  // there. Real device builds are completely unaffected by this code.
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: _desktopWindowSize,
      minimumSize: _desktopWindowSize,
      maximumSize: _desktopWindowSize, // locked — no resizing, stays phone-shaped
      center: true,
      title: 'DHA',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: ZameenCloneApp()));
}

class ZameenCloneApp extends ConsumerWidget {
  const ZameenCloneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'DHA',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
