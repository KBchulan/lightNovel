// ****************************************************************************
//
// @file       settings_sheet.dart
// @brief      设置功能底部弹出组件
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/reading_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({super.key});

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // 临时保存设置
  late LayoutSettings _layoutSettings;
  late AppearanceSettings _appearanceSettings;
  late DisplaySettings _displaySettings;
  late ReadingMode _readingMode;

  // 跟踪当前设置是否已修改
  bool _hasChanges = false;

  // 预设颜色 - 为亮色主题准备的
  final List<Color> _lightBackgroundColors = [
    Colors.white,
    const Color(0xFFF5F5DC), // 米色
    const Color(0xFFF8F0E3), // 浅米色
    const Color(0xFFE0E0E0), // 浅灰色
    const Color(0xFFECF0F1), // 浅蓝灰色
  ];

  final List<Color> _lightTextColors = [
    Colors.black,
    Colors.black87,
    const Color(0xFF333333), // 深灰色
    const Color(0xFF4A4A4A), // 灰色
    const Color(0xFF666666), // 中灰色
  ];

  // 预设颜色 - 为暗色主题准备的
  final List<Color> _darkBackgroundColors = [
    Colors.black,
    const Color(0xFF121212), // 近黑色
    const Color(0xFF1E1E1E), // 暗灰色
    const Color(0xFF2C3E50), // 深蓝色
    const Color(0xFF1A237E), // 深靛蓝色
  ];

  final List<Color> _darkTextColors = [
    Colors.white,
    Colors.white70,
    const Color(0xFFE0E0E0), // 浅灰色
    const Color(0xFFBDBDBD), // 中灰色
    const Color(0xFFCFD8DC), // 浅蓝灰色
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);

    // 获取当前设置
    final readingState = ref.read(readingNotifierProvider);
    _layoutSettings = readingState.layoutSettings;
    _appearanceSettings = readingState.appearanceSettings;
    _displaySettings = readingState.displaySettings;
    _readingMode = readingState.readingMode;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 应用当前设置
  void _applySettings() {
    if (!_hasChanges) return;

    final notifier = ref.read(readingNotifierProvider.notifier);
    notifier.updateLayoutSettings(_layoutSettings);
    notifier.updateAppearanceSettings(_appearanceSettings);
    notifier.updateDisplaySettings(_displaySettings);
    notifier.setReadingMode(_readingMode);

    setState(() {
      _hasChanges = false;
    });
  }

  // 重置所有设置
  void _resetSettings() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    setState(() {
      _layoutSettings = LayoutSettings.defaultSettings;
      _appearanceSettings = AppearanceSettings.getDefaultSettings(isDark);
      _displaySettings = DisplaySettings.defaultSettings;
      _readingMode = ReadingMode.scroll;
      _hasChanges = true;
    });
  }

  // 显示颜色选择器对话框
  void _showColorPicker({required bool isBackground}) {
    final currentColor = isBackground
        ? _appearanceSettings.backgroundColor
        : _appearanceSettings.textColor;

    Color pickedColor = currentColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBackground ? '背景颜色' : '文字颜色'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) {
              pickedColor = color;
            },
            pickerAreaHeightPercent: 0.8,
            enableAlpha: true,
            displayThumbColor: true,
            labelTypes: const [],
            paletteType: PaletteType.hsv,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (isBackground) {
                  _appearanceSettings = _appearanceSettings.copyWith(
                    backgroundColor: pickedColor,
                    useCustomColors: true,
                  );
                } else {
                  _appearanceSettings = _appearanceSettings.copyWith(
                    textColor: pickedColor,
                    useCustomColors: true,
                  );
                }
                _hasChanges = true;
              });
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: Column(
              children: [
                // 顶部拖动条
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withAlpha(25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // 标题栏
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '设置',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text('重置'),
                        onPressed: _resetSettings,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // 预览文本卡片
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: Card(
                    elevation: 0,
                    color: _appearanceSettings.backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withAlpha(80),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _layoutSettings.leftRightPadding,
                        vertical: _layoutSettings.topBottomPadding,
                      ),
                      child: Text(
                        '　当一个坚定的独身主义者因痛苦而感到孤独与无助时，他或许已是走向末路。',
                        style: TextStyle(
                          fontSize: _layoutSettings.fontSize,
                          height: _layoutSettings.lineHeight,
                          fontWeight: _layoutSettings.fontWeight,
                          color: _appearanceSettings.textColor,
                        ),
                      ),
                    ),
                  ),
                ),

                // Tab栏
                TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 2.5,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: '排版'),
                    Tab(text: '外观'),
                    Tab(text: '显示'),
                    Tab(text: '模式'),
                  ],
                ),

                // Tab内容
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLayoutSettings(theme, scrollController),
                      _buildAppearanceSettings(theme, scrollController, isDark),
                      _buildDisplaySettings(theme, scrollController),
                      _buildReadingModeSettings(theme, scrollController),
                    ],
                  ),
                ),

                // 底部按钮
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _hasChanges ? _applySettings : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '应用设置',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 构建排版设置
  Widget _buildLayoutSettings(
      ThemeData theme, ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 字体大小
          _buildSettingTitle('字体大小'),
          _buildNormalizedSlider(
            value: _layoutSettings.fontSize,
            min: 12.0,
            max: 24.0,
            defaultValue: 16.0,
            onChanged: (value) {
              setState(() {
                _layoutSettings = _layoutSettings.copyWith(fontSize: value);
                _hasChanges = true;
              });
            },
            valueDisplayBuilder: (value) => value.toStringAsFixed(1),
          ),

          const SizedBox(height: 24),

          // 行间距
          _buildSettingTitle('行间距'),
          _buildNormalizedSlider(
            value: _layoutSettings.lineHeight,
            min: 1.2,
            max: 2.1,
            defaultValue: 1.5,
            onChanged: (value) {
              setState(() {
                _layoutSettings = _layoutSettings.copyWith(lineHeight: value);
                _hasChanges = true;
              });
            },
            valueDisplayBuilder: (value) => value.toStringAsFixed(1),
          ),

          const SizedBox(height: 24),

          // 字重
          _buildSettingTitle('字重'),
          _buildNormalizedSlider(
            value: _getFontWeightValue(_layoutSettings.fontWeight),
            min: 0,
            max: 3,
            defaultValue: 1,
            onChanged: (value) {
              final fontWeight = _getFontWeightFromValue(value);
              setState(() {
                _layoutSettings =
                    _layoutSettings.copyWith(fontWeight: fontWeight);
                _hasChanges = true;
              });
            },
            valueDisplayBuilder: (value) =>
                _getFontWeightName(_getFontWeightFromValue(value)),
          ),

          const SizedBox(height: 24),

          // 上下边距
          _buildSettingTitle('上下边距'),
          _buildNormalizedSlider(
            value: _layoutSettings.topBottomPadding,
            min: 8.0,
            max: 32.0,
            defaultValue: 16.0,
            onChanged: (value) {
              setState(() {
                _layoutSettings =
                    _layoutSettings.copyWith(topBottomPadding: value);
                _hasChanges = true;
              });
            },
            valueDisplayBuilder: (value) => value.toStringAsFixed(1),
          ),

          const SizedBox(height: 24),

          // 左右边距
          _buildSettingTitle('左右边距'),
          _buildNormalizedSlider(
            value: _layoutSettings.leftRightPadding,
            min: 8.0,
            max: 32.0,
            defaultValue: 16.0,
            onChanged: (value) {
              setState(() {
                _layoutSettings =
                    _layoutSettings.copyWith(leftRightPadding: value);
                _hasChanges = true;
              });
            },
            valueDisplayBuilder: (value) => value.toStringAsFixed(1),
          ),
        ],
      ),
    );
  }

  // 标准化滑动条组件 - 在初始状态下位置一致，连续滑动
  Widget _buildNormalizedSlider({
    required double value,
    required double min,
    required double max,
    required double defaultValue,
    required ValueChanged<double> onChanged,
    required String Function(double) valueDisplayBuilder,
  }) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              showValueIndicator: ShowValueIndicator.never,
              trackHeight: 2.5,
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
              overlayShape: SliderComponentShape.noOverlay,
              tickMarkShape: SliderTickMarkShape.noTickMark,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Slider(
                  value: value,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 36,
          alignment: Alignment.center,
          child: Text(
            valueDisplayBuilder(value),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // 字重转换相关工具方法
  double _getFontWeightValue(FontWeight weight) {
    switch (weight) {
      case FontWeight.w300:
        return 0;
      case FontWeight.w400:
        return 1;
      case FontWeight.w500:
        return 2;
      case FontWeight.w600:
        return 3;
      default:
        return 1; // normal
    }
  }

  FontWeight _getFontWeightFromValue(double value) {
    // 连续滑动情况下，根据value范围划分字重
    if (value < 0.5) return FontWeight.w300;
    if (value < 1.5) return FontWeight.w400;
    if (value < 2.5) return FontWeight.w500;
    return FontWeight.w600;
  }

  String _getFontWeightName(FontWeight weight) {
    switch (weight) {
      case FontWeight.w300:
        return '细体';
      case FontWeight.w400:
        return '常规';
      case FontWeight.w500:
        return '中等';
      case FontWeight.w600:
        return '粗体';
      default:
        return '常规';
    }
  }

  // 构建外观设置
  Widget _buildAppearanceSettings(
      ThemeData theme, ScrollController scrollController, bool isDark) {
    final backgroundColors = isDark ? _darkBackgroundColors : _lightBackgroundColors;
    final textColors = isDark ? _darkTextColors : _lightTextColors;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 背景颜色
          _buildSettingTitle('背景颜色'),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: backgroundColors.length + 1,
              itemBuilder: (context, index) {
                if (index < backgroundColors.length) {
                  final color = backgroundColors[index];
                  final isSelected = _appearanceSettings.backgroundColor == color && !_appearanceSettings.useCustomColors;

                  return _buildColorItemHorizontal(
                    color,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _appearanceSettings = _appearanceSettings.copyWith(
                          backgroundColor: color,
                          useCustomColors: false,
                        );
                        _hasChanges = true;
                      });
                    },
                  );
                } else {
                  return _buildCustomColorItemHorizontal(
                    isSelected: _appearanceSettings.useCustomColors,
                    onTap: () => _showColorPicker(isBackground: true),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 20),

          // 文字颜色
          _buildSettingTitle('文字颜色'),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: textColors.length + 1, // +1 for custom color
              itemBuilder: (context, index) {
                if (index < textColors.length) {
                  final color = textColors[index];
                  final isSelected = _appearanceSettings.textColor == color && !_appearanceSettings.useCustomColors;

                  return _buildColorItemHorizontal(
                    color,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _appearanceSettings = _appearanceSettings.copyWith(
                          textColor: color,
                          useCustomColors: false,
                        );
                        _hasChanges = true;
                      });
                    },
                  );
                } else {
                  return _buildCustomColorItemHorizontal(
                    isSelected: _appearanceSettings.useCustomColors,
                    onTap: () => _showColorPicker(isBackground: false),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // 构建显示设置
  Widget _buildDisplaySettings(
      ThemeData theme, ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingTitle('状态栏显示'),

          // 显示电量
          ListTile(
            contentPadding: const EdgeInsets.only(left: 12.0),
            title: const Text('电池状态', style: TextStyle(fontSize: 15.2)),
            trailing: Switch(
              value: _displaySettings.showBattery,
              onChanged: (value) {
                setState(() {
                  _displaySettings =
                      _displaySettings.copyWith(showBattery: value);
                  _hasChanges = true;
                });
              },
            ),
          ),

          // 显示时间
          ListTile(
            contentPadding: const EdgeInsets.only(left: 12.0),
            title: const Text('当前时间', style: TextStyle(fontSize: 15.2)),
            trailing: Switch(
              value: _displaySettings.showTime,
              onChanged: (value) {
                setState(() {
                  _displaySettings = _displaySettings.copyWith(showTime: value);
                  _hasChanges = true;
                });
              },
            ),
          ),

          // 显示章节名称
          ListTile(
            contentPadding: const EdgeInsets.only(left: 12.0),
            title: const Text('章节名称', style: TextStyle(fontSize: 15.2)),
            trailing: Switch(
              value: _displaySettings.showChapterTitle,
              onChanged: (value) {
                setState(() {
                  _displaySettings =
                      _displaySettings.copyWith(showChapterTitle: value);
                  _hasChanges = true;
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // 显示效果预览
          _buildSettingTitle('效果预览'),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 16.0),
            elevation: 0,
            color: _appearanceSettings.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withAlpha(80),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // 左侧
                  Expanded(
                    child: _displaySettings.showChapterTitle
                        ? Text(
                            '第一卷 序章',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color:
                                  _appearanceSettings.textColor.withAlpha(201),
                            ),
                          )
                        : const SizedBox(),
                  ),

                  // 右侧
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_displaySettings.showBattery)
                        Row(
                          children: [
                            Icon(
                              Icons.battery_full,
                              size: 18,
                              color:
                                  _appearanceSettings.textColor.withAlpha(201),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '101%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _appearanceSettings.textColor
                                    .withAlpha(201),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      if (_displaySettings.showTime)
                        Text(
                          '25:01',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _appearanceSettings.textColor.withAlpha(201),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建阅读模式设置
  Widget _buildReadingModeSettings(ThemeData theme, ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingTitle('阅读模式'),

          // 阅读模式选项卡
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer.withAlpha(120),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // 滚动模式
                RadioListTile<ReadingMode>(
                  title: const Text('滚动模式'),
                  subtitle: const Text('上下滚动阅读内容'),
                  value: ReadingMode.scroll,
                  groupValue: _readingMode,
                  onChanged: (value) {
                    setState(() {
                      _readingMode = value!;
                      _hasChanges = true;
                    });
                  },
                ),

                const SizedBox(height: 6),

                // 翻页模式
                RadioListTile<ReadingMode>(
                  title: Row(
                    children: [
                      const Text('翻页模式'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(40),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '开发中',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Text('左右翻页阅读内容'),
                  value: ReadingMode.page,
                  groupValue: _readingMode,
                  onChanged: null, // 暂时禁用
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: theme.colorScheme.errorContainer.withAlpha(40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '翻页模式暂未开发完成，敬请期待后续更新',
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 设置标题组件
  Widget _buildSettingTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 水平排列的颜色选项
  Widget _buildColorItemHorizontal(
    Color color, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withAlpha(80),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: isSelected
            ? Center(
                child: Icon(
                  Icons.check,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black
                      : Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  // 水平排列的自定义颜色选项
  Widget _buildCustomColorItemHorizontal({
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withAlpha(80),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.color_lens,
              size: 22,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            Text(
              '自定义',
              style: TextStyle(
                fontSize: 9,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
