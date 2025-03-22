// ****************************************************************************
//
// @file       reading_provider.dart
// @brief      阅读状态管理
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/chapter.dart';
import '../models/reading_progress.dart';

part 'reading_provider.g.dart';

enum ReadingMode {
  page,    // 翻页模式
  scroll,  // 滚动模式
}

enum ReadingTheme {
  light,   // 日间模式
  dark,    // 夜间模式
  sepia,   // 护眼模式
}

@riverpod
class ReadingNotifier extends _$ReadingNotifier {
  @override
  ReadingState build() => const ReadingState();

  void setReadingMode(ReadingMode mode) {
    state = state.copyWith(readingMode: mode);
  }

  void setReadingTheme(ReadingTheme theme) {
    state = state.copyWith(readingTheme: theme);
  }

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size);
  }

  void setLineHeight(double height) {
    state = state.copyWith(lineHeight: height);
  }

  void setParagraphSpacing(double spacing) {
    state = state.copyWith(paragraphSpacing: spacing);
  }

  void setBrightness(double brightness) {
    state = state.copyWith(brightness: brightness);
  }

  void setCurrentChapter(Chapter chapter) {
    state = state.copyWith(currentChapter: chapter);
  }

  void setReadingProgress(ReadingProgress progress) {
    state = state.copyWith(readingProgress: progress);
  }

  void toggleFullScreen() {
    state = state.copyWith(isFullScreen: !state.isFullScreen);
  }

  void toggleShowControls() {
    state = state.copyWith(showControls: !state.showControls);
  }

  void setShowControls(bool show) {
    state = state.copyWith(showControls: show);
  }
}

class ReadingState {
  final ReadingMode readingMode;
  final ReadingTheme readingTheme;
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final double brightness;
  final Chapter? currentChapter;
  final ReadingProgress? readingProgress;
  final bool isFullScreen;
  final bool showControls;

  const ReadingState({
    this.readingMode = ReadingMode.page,
    this.readingTheme = ReadingTheme.light,
    this.fontSize = 16.0,
    this.lineHeight = 1.5,
    this.paragraphSpacing = 1.0,
    this.brightness = 1.0,
    this.currentChapter,
    this.readingProgress,
    this.isFullScreen = false,
    this.showControls = false,
  });

  ReadingState copyWith({
    ReadingMode? readingMode,
    ReadingTheme? readingTheme,
    double? fontSize,
    double? lineHeight,
    double? paragraphSpacing,
    double? brightness,
    Chapter? currentChapter,
    ReadingProgress? readingProgress,
    bool? isFullScreen,
    bool? showControls,
  }) {
    return ReadingState(
      readingMode: readingMode ?? this.readingMode,
      readingTheme: readingTheme ?? this.readingTheme,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      brightness: brightness ?? this.brightness,
      currentChapter: currentChapter ?? this.currentChapter,
      readingProgress: readingProgress ?? this.readingProgress,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      showControls: showControls ?? this.showControls,
    );
  }
} 