// ****************************************************************************
//
// @file       reading_provider.dart
// @brief      阅读相关的状态管理
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'api_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/material.dart';
import '../models/chapter.dart';
import '../models/reading_progress.dart';
import '../models/read_history.dart';
import '../theme/app_theme.dart';

part 'reading_provider.g.dart';

// 阅读模式
enum ReadingMode {
  scroll, // 滚动模式
  page, // 翻页模式
}

// 显示模式设置
class DisplaySettings {
  final bool showBattery;
  final bool showTime;
  final bool showChapterTitle;

  const DisplaySettings({
    this.showBattery = true,
    this.showTime = true,
    this.showChapterTitle = true,
  });

  DisplaySettings copyWith({
    bool? showBattery,
    bool? showTime,
    bool? showChapterTitle,
  }) {
    return DisplaySettings(
      showBattery: showBattery ?? this.showBattery,
      showTime: showTime ?? this.showTime,
      showChapterTitle: showChapterTitle ?? this.showChapterTitle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'showBattery': showBattery,
      'showTime': showTime,
      'showChapterTitle': showChapterTitle,
    };
  }

  factory DisplaySettings.fromJson(Map<String, dynamic> json) {
    return DisplaySettings(
      showBattery: json['showBattery'] ?? true,
      showTime: json['showTime'] ?? true,
      showChapterTitle: json['showChapterTitle'] ?? true,
    );
  }

  static const DisplaySettings defaultSettings = DisplaySettings();
}

// 阅读布局设置
class LayoutSettings {
  final double fontSize;
  final double lineHeight;
  final FontWeight fontWeight;
  final double topBottomPadding;
  final double leftRightPadding;

  const LayoutSettings({
    this.fontSize = 16.0,
    this.lineHeight = 1.5,
    this.fontWeight = FontWeight.normal,
    this.topBottomPadding = 16.0,
    this.leftRightPadding = 16.0,
  });

  LayoutSettings copyWith({
    double? fontSize,
    double? lineHeight,
    FontWeight? fontWeight,
    double? topBottomPadding,
    double? leftRightPadding,
  }) {
    return LayoutSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontWeight: fontWeight ?? this.fontWeight,
      topBottomPadding: topBottomPadding ?? this.topBottomPadding,
      leftRightPadding: leftRightPadding ?? this.leftRightPadding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'fontWeight': fontWeight.index,
      'topBottomPadding': topBottomPadding,
      'leftRightPadding': leftRightPadding,
    };
  }

  factory LayoutSettings.fromJson(Map<String, dynamic> json) {
    return LayoutSettings(
      fontSize: json['fontSize'] ?? 16.0,
      lineHeight: json['lineHeight'] ?? 1.5,
      fontWeight: FontWeight.values[json['fontWeight'] ?? 3],
      topBottomPadding: json['topBottomPadding'] ?? 16.0,
      leftRightPadding: json['leftRightPadding'] ?? 16.0,
    );
  }

  static const LayoutSettings defaultSettings = LayoutSettings();
}

// 外观设置
class AppearanceSettings {
  final Color backgroundColor;
  final Color textColor;
  final bool useCustomColors;

  const AppearanceSettings({
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black87,
    this.useCustomColors = false,
  });

  AppearanceSettings copyWith({
    Color? backgroundColor,
    Color? textColor,
    bool? useCustomColors,
  }) {
    return AppearanceSettings(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      useCustomColors: useCustomColors ?? this.useCustomColors,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'backgroundColor': backgroundColor.toARGB32(),
      'textColor': textColor.toARGB32(),
      'useCustomColors': useCustomColors,
    };
  }

  factory AppearanceSettings.fromJson(Map<String, dynamic> json) {
    return AppearanceSettings(
      backgroundColor:
          Color(json['backgroundColor'] ?? Colors.white.toARGB32()),
      textColor: Color(json['textColor'] ?? Colors.black87.toARGB32()),
      useCustomColors: json['useCustomColors'] ?? false,
    );
  }

  // 获取适合当前主题的默认设置
  static AppearanceSettings getDefaultSettings(bool isDark) {
    return isDark
        ? const AppearanceSettings(
            backgroundColor: Colors.black,
            textColor: Colors.white,
            useCustomColors: false,
          )
        : const AppearanceSettings(
            backgroundColor: Colors.white,
            textColor: Colors.black87,
            useCustomColors: false,
          );
  }
}

// 阅读状态
class ReadingState {
  final Chapter? currentChapter;
  final ReadingMode readingMode;
  final bool showControls;
  final ReadingProgress? readingProgress;
  final List<ReadHistory> readHistory;
  final LayoutSettings layoutSettings;
  final AppearanceSettings appearanceSettings;
  final DisplaySettings displaySettings;

  const ReadingState({
    this.currentChapter,
    this.readingMode = ReadingMode.scroll,
    this.showControls = true,
    this.readingProgress,
    this.readHistory = const [],
    this.layoutSettings = LayoutSettings.defaultSettings,
    this.appearanceSettings = const AppearanceSettings(),
    this.displaySettings = DisplaySettings.defaultSettings,
  });

  ReadingState copyWith({
    Chapter? currentChapter,
    ReadingMode? readingMode,
    bool? showControls,
    ReadingProgress? readingProgress,
    List<ReadHistory>? readHistory,
    LayoutSettings? layoutSettings,
    AppearanceSettings? appearanceSettings,
    DisplaySettings? displaySettings,
  }) {
    return ReadingState(
      currentChapter: currentChapter ?? this.currentChapter,
      readingMode: readingMode ?? this.readingMode,
      showControls: showControls ?? this.showControls,
      readingProgress: readingProgress ?? this.readingProgress,
      readHistory: readHistory ?? this.readHistory,
      layoutSettings: layoutSettings ?? this.layoutSettings,
      appearanceSettings: appearanceSettings ?? this.appearanceSettings,
      displaySettings: displaySettings ?? this.displaySettings,
    );
  }
}

@riverpod
class ReadingNotifier extends _$ReadingNotifier {
  late SharedPreferences _prefs;
  final String _prefsKeyBase = 'reading_settings';

  // 获取当前主题模式下的存储键
  String _getCurrentPrefsKey() {
    final themeMode = ref.read(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    return '${_prefsKeyBase}_${isDark ? 'dark' : 'light'}';
  }

  @override
  ReadingState build() {
    _loadSettings();
    return const ReadingState();
  }

  // 重新加载设置
  Future<void> reloadSettings() async {
    await _loadSettings();
  }

  // 加载设置
  Future<void> _loadSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // 获取当前主题模式下的设置键
      final settingsKey = _getCurrentPrefsKey();
      final settingsJson = _prefs.getString(settingsKey);

      if (settingsJson != null) {
        final Map<String, dynamic> settings = jsonDecode(settingsJson);

        final layoutSettings = settings['layoutSettings'] != null
            ? LayoutSettings.fromJson(settings['layoutSettings'])
            : LayoutSettings.defaultSettings;

        // 确定当前是否为暗色模式
        final themeMode = ref.read(themeNotifierProvider);
        final isDark = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                    Brightness.dark);

        final appearanceSettings = settings['appearanceSettings'] != null
            ? AppearanceSettings.fromJson(settings['appearanceSettings'])
            : AppearanceSettings.getDefaultSettings(isDark);

        final displaySettings = settings['displaySettings'] != null
            ? DisplaySettings.fromJson(settings['displaySettings'])
            : DisplaySettings.defaultSettings;

        final readingMode = settings['readingMode'] != null
            ? ReadingMode.values[settings['readingMode']]
            : ReadingMode.scroll;

        state = state.copyWith(
          layoutSettings: layoutSettings,
          appearanceSettings: appearanceSettings,
          displaySettings: displaySettings,
          readingMode: readingMode,
        );

        debugPrint('✅ 已加载主题模式(${isDark ? "暗色" : "亮色"})的阅读设置');
      } else {
        _initDefaultSettings();
        debugPrint('⚠️ 未找到保存的阅读设置，使用默认值');
      }
    } catch (e) {
      debugPrint('❌ 加载阅读设置错误: $e');
    }
  }

  // 初始化默认设置
  void _initDefaultSettings() {
    // 确定当前是否为暗色模式
    final themeMode = ref.read(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    state = state.copyWith(
      layoutSettings: LayoutSettings.defaultSettings,
      appearanceSettings: AppearanceSettings.getDefaultSettings(isDark),
      displaySettings: DisplaySettings.defaultSettings,
      readingMode: ReadingMode.scroll,
    );
  }

  // 保存设置
  Future<void> _saveSettings() async {
    try {
      final Map<String, dynamic> settings = {
        'layoutSettings': state.layoutSettings.toJson(),
        'appearanceSettings': state.appearanceSettings.toJson(),
        'displaySettings': state.displaySettings.toJson(),
        'readingMode': state.readingMode.index,
      };

      final settingsJson = jsonEncode(settings);

      // 获取当前主题模式下的设置键
      final settingsKey = _getCurrentPrefsKey();
      await _prefs.setString(settingsKey, settingsJson);

      final themeMode = ref.read(themeNotifierProvider);
      final isDark = themeMode == ThemeMode.dark ||
          (themeMode == ThemeMode.system &&
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark);

      debugPrint('✅ 已保存主题模式(${isDark ? "暗色" : "亮色"})的阅读设置');
    } catch (e) {
      debugPrint('❌ 保存阅读设置错误: $e');
    }
  }

  // 设置当前章节
  void setCurrentChapter(Chapter chapter) {
    state = state.copyWith(currentChapter: chapter);
  }

  // 设置阅读模式
  void setReadingMode(ReadingMode mode) {
    state = state.copyWith(readingMode: mode);
    _saveSettings();
  }

  // 切换控制面板显示状态
  void toggleShowControls() {
    state = state.copyWith(showControls: !state.showControls);
  }

  // 设置控制面板显示状态
  void setShowControls(bool show) {
    state = state.copyWith(showControls: show);
  }

  // 更新布局设置
  void updateLayoutSettings(LayoutSettings settings) {
    state = state.copyWith(layoutSettings: settings);
    _saveSettings();
  }

  // 更新外观设置
  void updateAppearanceSettings(AppearanceSettings settings) {
    state = state.copyWith(appearanceSettings: settings);
    _saveSettings();
  }

  // 更新显示设置
  void updateDisplaySettings(DisplaySettings settings) {
    state = state.copyWith(displaySettings: settings);
    _saveSettings();
  }

  // 重置所有设置
  void resetSettings(bool isDark) {
    state = state.copyWith(
      layoutSettings: LayoutSettings.defaultSettings,
      appearanceSettings: AppearanceSettings.getDefaultSettings(isDark),
      displaySettings: DisplaySettings.defaultSettings,
      readingMode: ReadingMode.scroll,
    );
    _saveSettings();
  }

  // 更新阅读进度
  Future<void> updateReadingProgress({
    required String novelId,
    required int volumeNumber,
    required int chapterNumber,
    required int position,
  }) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      // 同时更新阅读进度和历史
      await Future.wait([
        apiClient.updateReadProgress(
          novelId: novelId,
          volumeNumber: volumeNumber,
          chapterNumber: chapterNumber,
          position: position,
        ),
        apiClient.updateReadHistory(novelId),
      ]);

      // 更新本地状态
      state = state.copyWith(
        readingProgress: ReadingProgress(
          id: '',
          deviceId: '',
          novelId: novelId,
          volumeNumber: volumeNumber,
          chapterNumber: chapterNumber,
          position: position,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('❌ 更新阅读进度错误: $e');
      rethrow;
    }
  }

  // 获取阅读进度
  Future<void> fetchReadingProgress(String novelId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final progress = await apiClient.getReadProgress(novelId);
      if (progress == null) {
        state = state.copyWith(readingProgress: null);
        return;
      }
      state = state.copyWith(readingProgress: progress);
    } catch (e) {
      state = state.copyWith(readingProgress: null);
      rethrow;
    }
  }

  // 获取阅读历史
  Future<void> fetchReadHistory() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final history = await apiClient.getReadHistory();
      state = state.copyWith(readHistory: history);
    } catch (e) {
      state = state.copyWith(readHistory: []);
    }
  }

  // 清空阅读历史
  Future<void> clearReadHistory() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.clearReadHistory();
      state = state.copyWith(readHistory: []);
    } catch (e) {
      rethrow;
    }
  }

  // 删除阅读进度
  Future<void> deleteReadingProgress(String novelId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.deleteReadProgress(novelId);
      if (state.readingProgress?.novelId == novelId) {
        state = state.copyWith(readingProgress: null);
      }
    } catch (e) {
      rethrow;
    }
  }
}
