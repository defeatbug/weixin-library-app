import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowManagerInit {
  static Future<void> init() async {
    if (!_isDesktop) return;

    await windowManager.ensureInitialized();

    final options = WindowOptions(
      size: const Size(1100, 700),
      minimumSize: const Size(800, 500),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      windowButtonVisibility: true,
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  static bool get _isDesktop {
    return !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
  }
}
