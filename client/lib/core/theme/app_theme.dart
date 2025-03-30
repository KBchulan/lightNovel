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
import '../providers/reading_provider.dart';

part 'app_theme.g.dart';

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    state = mode;

    // 通知阅读提供程序主题已更改
    Future.microtask(() {
      if (ref.exists(readingNotifierProvider)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(readingNotifierProvider.notifier).reloadSettings();
        });
      }
    });
  }

  void toggleThemeMode() {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(newMode);
  }
}

class AppTheme {
  static const _subThemesData = FlexSubThemesData(
    blendOnColors: false,
    useTextTheme: true,
    useM2StyleDividerInM3: true,
    alignedDropdown: true,
    useInputDecoratorThemeInDialogs: true,
    defaultRadius: 8,
    fabUseShape: true,
    interactionEffects: true,
    thinBorderWidth: 1.0,
    thickBorderWidth: 2.0,
    textButtonRadius: 8.0,
    elevatedButtonRadius: 8.0,
    outlinedButtonRadius: 8.0,
    toggleButtonsRadius: 8.0,
    inputDecoratorRadius: 8.0,
    cardRadius: 12.0,
    popupMenuRadius: 8.0,
    dialogRadius: 12.0,
    timePickerDialogRadius: 12.0,
    bottomSheetRadius: 16.0,
    navigationBarIndicatorRadius: 8.0,
    tabBarIndicatorWeight: 2.0,
    bottomNavigationBarElevation: 2.0,
    navigationBarHeight: 56.0,
    drawerWidth: 304.0,
    dialogBackgroundSchemeColor: SchemeColor.surface,
    datePickerHeaderBackgroundSchemeColor: SchemeColor.primary,
    snackBarBackgroundSchemeColor: SchemeColor.inverseSurface,
  );

  static const _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
    },
  );

  static final light = FlexThemeData.light(
    scheme: FlexScheme.blue,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 7,
    subThemesData: _subThemesData.copyWith(
      blendOnLevel: 10,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
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
  ).copyWith(
    pageTransitionsTheme: _pageTransitionsTheme,
  );

  static final dark = FlexThemeData.dark(
    scheme: FlexScheme.blue,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 13,
    subThemesData: _subThemesData.copyWith(
      blendOnLevel: 20,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
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
  ).copyWith(
    pageTransitionsTheme: _pageTransitionsTheme,
  );
}
