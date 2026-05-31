import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/application.dart';
import 'config/app_router.dart';
import 'config/app_theme.dart';
import 'config/initializers/window_manager_init.dart';

class App extends StatefulWidget {
  const App({super.key});

  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');
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
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '微信读书',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
