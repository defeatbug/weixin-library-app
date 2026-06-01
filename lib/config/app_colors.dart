import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 微信读书风格配色，随明暗模式切换
class AppColors {
  AppColors._();

  static bool get _isDark => appTheme.brightness == Brightness.dark;

  static const primary = Color(0xFF0091FF);

  static Color get primaryLight =>
      _isDark ? primary.withValues(alpha: 0.2) : const Color(0xFFE6F4FF);

  static Color get background =>
      _isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5);

  static Color get card =>
      _isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF);

  static Color get searchBg =>
      _isDark ? const Color(0xFF3A3A3C) : const Color(0xFFEDEDED);

  static Color get textPrimary =>
      _isDark ? const Color(0xFFE5E5EA) : const Color(0xFF333333);

  static Color get textSecondary =>
      _isDark ? const Color(0xFF8E8E93) : const Color(0xFF999999);

  static Color get textHint =>
      _isDark ? const Color(0xFF636366) : const Color(0xFF8A8A8E);

  static Color get divider =>
      _isDark ? const Color(0xFF3A3A3C) : const Color(0xFFEEEEEE);

  static Color get border =>
      _isDark ? const Color(0xFF48484A) : const Color(0xFFE8E8E8);

  static Color get vipGold => const Color(0xFFC7922A);

  static Color get vipBg =>
      _isDark ? const Color(0xFF3D3520) : const Color(0xFFFFF8E7);

  static const iconYellow = Color(0xFFFFB800);
  static const iconOrange = Color(0xFFFF8C42);
  static const iconCoral = Color(0xFFFF6B6B);
  static const iconTeal = Color(0xFF4ECDC4);
  static const iconBlue = Color(0xFF5B9BD5);
  static const iconPurple = Color(0xFF9B59B6);
}
