import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/app_config.dart';
import 'config/application.dart';
import 'config/app_router.dart';
import 'config/app_theme.dart';
import 'config/initializers/window_manager_init.dart';

class App extends StatefulWidget {
  const App({super.key});

  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await dotenv.load(fileName: '.env.example');
    } catch (_) {
      try {
        await dotenv.load(fileName: '.env');
      } catch (_) {}
    }
    await appConfig.init();
    await Application.init();
    await WindowManagerInit.init();
    runApp(const App());
  }

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
    };
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    appTheme.onPlatformBrightnessChanged();
    super.didChangePlatformBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: appTheme.version,
      builder: (context, _, __) {
        return MaterialApp.router(
          title: '微信读书',
          theme: appTheme.data,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
