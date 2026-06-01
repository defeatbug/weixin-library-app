import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_config.dart';

AppTheme get appTheme => AppTheme._instance ??= AppTheme();

class AppTheme {
  static AppTheme? _instance;

  /// 主题变更时递增，用于触发 App 重建
  final ValueNotifier<int> version = ValueNotifier(0);

  Brightness get platformBrightness =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  String get platformBrightnessString => platformBrightness.toString();

  Brightness get brightness {
    final saved = appConfig.brightness;
    if (saved == null) return platformBrightness;
    if (saved == Brightness.dark.toString()) return Brightness.dark;
    return Brightness.light;
  }

  bool get auto => appConfig.brightness == null;

  String get brightnessState {
    if (auto) return 'auto';
    return brightness == Brightness.dark ? 'enabled' : 'disabled';
  }

  String get brightnessStateLabel {
    switch (brightnessState) {
      case 'auto':
        return '跟随系统';
      case 'enabled':
        return '已开启';
      default:
        return '已关闭';
    }
  }

  ThemeData get data => brightness == Brightness.dark ? dark : light;

  ThemeData get light => _buildTheme(Brightness.light);
  ThemeData get dark => _buildTheme(Brightness.dark);

  Future<void> setFollowSystem(bool follow) async {
    if (follow) {
      appConfig.brightness = null;
    } else {
      appConfig.brightness = platformBrightnessString;
    }
    await appConfig.save();
    notifyChanged();
  }

  Future<void> setDarkMode(bool enabled) async {
    appConfig.brightness =
        enabled ? Brightness.dark.toString() : Brightness.light.toString();
    await appConfig.save();
    notifyChanged();
  }

  void onPlatformBrightnessChanged() {
    if (auto) notifyChanged();
  }

  void notifyChanged() => version.value++;

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const primary = Color(0xFF0091FF);
    final bg = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5);
    final card = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF);
    final searchBg = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFEDEDED);
    final textPrimary = isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333);
    final textSecondary = isDark ? const Color(0xFF8E8E93) : const Color(0xFF999999);
    final divider = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFEEEEEE);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      surface: card,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outlineVariant: divider,
      surfaceContainerHighest: searchBg,
      surfaceContainerLow: bg,
      error: const Color(0xFFFF453A),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bg,
        foregroundColor: textPrimary,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 0.5),
      listTileTheme: ListTileThemeData(
        textColor: textPrimary,
        iconColor: isDark ? const Color(0xFF636366) : const Color(0xFF8A8A8E),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isDark ? const Color(0xFF636366) : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return isDark ? const Color(0xFF48484A) : const Color(0xFFE9E9EA);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: searchBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
