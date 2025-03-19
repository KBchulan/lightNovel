// ****************************************************************************
//
// @file       app_theme.dart
// @brief      应用主题
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_theme.g.dart';

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  void toggleThemeMode() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

class AppTheme {
  static final light = FlexThemeData.light(
    scheme: FlexScheme.blue,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 7,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
      useTextTheme: true,
      useM2StyleDividerInM3: true,
      alignedDropdown: true,
      useInputDecoratorThemeInDialogs: true,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // 添加自定义颜色
    colors: const FlexSchemeColor(
      primary: Color(0xFF2196F3),
      primaryContainer: Color(0xFFBBDEFB),
      secondary: Color(0xFF26A69A),
      secondaryContainer: Color(0xFFB2DFDB),
      tertiary: Color(0xFF7E57C2),
      tertiaryContainer: Color(0xFFD1C4E9),
      appBarColor: Color(0xFF2196F3),
      error: Color(0xFFB00020),
    ),
  );

  static final dark = FlexThemeData.dark(
    scheme: FlexScheme.blue,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 13,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
      useTextTheme: true,
      useM2StyleDividerInM3: true,
      alignedDropdown: true,
      useInputDecoratorThemeInDialogs: true,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // 添加自定义颜色
    colors: const FlexSchemeColor(
      primary: Color(0xFF90CAF9),
      primaryContainer: Color(0xFF1976D2),
      secondary: Color(0xFF80CBC4),
      secondaryContainer: Color(0xFF00796B),
      tertiary: Color(0xFFB39DDB),
      tertiaryContainer: Color(0xFF512DA8),
      appBarColor: Color(0xFF1976D2),
      error: Color(0xFFCF6679),
    ),
  );
}
