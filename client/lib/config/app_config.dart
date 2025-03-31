// ****************************************************************************
//
// @file       app_config.dart
// @brief      App配置
//
// @author     KBchulan
// @date       2025/03/19
// @history
// ****************************************************************************

class AppConfig {
  static const String appName = 'LightNovel';
  static const String appVersion = '1.0.0';

  // API配置
  static const bool isDebug = true; // 调试模式

  // 在调试模式下使用本地服务器，否则使用生产服务器
  static String get apiBaseUrl {
    if (isDebug) {
      // return 'http://localhost:8080/api/v1'; // 本机服务器
      return 'http://120.27.201.149:8080/api/v1'; // 阿里云服务器
    }
    return 'https://chulan.xin/api/v1'; // 阿里云服务器 (https)
  }

  // 静态资源路径
  static String get staticUrl {
    if (isDebug) {
      // return 'http://localhost:8080'; // 本机服务器
      return 'http://120.27.201.149:8080'; // 阿里云服务器
    }
    return 'https://chulan.xin'; // 阿里云服务器(https)
  }

  static String get wsBaseUrl {
    if (isDebug) {
      // return 'ws://localhost:8080/api/v1/ws'; // 本机服务器
      return 'ws://120.27.201.149:8080/api/v1/ws'; // 阿里云服务器
    }
    return 'wss://chulan.xin/api/v1/ws'; // 阿里云服务器(https)
  }

  // 缓存配置
  static const int maxCacheSize = 100 * 1024 * 1024;
  static const Duration cacheDuration = Duration(days: 7);

  // 阅读设置默认值
  static const double defaultFontSize = 18.0;
  static const double defaultLineHeight = 1.5;
  static const String defaultFontFamily = 'NotoSansSC';

  // 主题配置
  static const bool defaultIsDarkMode = true;
  static const String defaultThemeColor = 'blue';

  // 阅读器配置
  static const bool defaultShowStatus = true;
  static const bool defaultKeepScreenOn = true;
  static const bool defaultShowProgress = true;

  // API超时设置
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // 本地存储键
  static const String deviceIdKey = 'device_id';
  static const String themeKey = 'theme';
  static const String fontSizeKey = 'font_size';
  static const String lineHeightKey = 'line_height';
  static const String fontFamilyKey = 'font_family';
  static const String readingModeKey = 'reading_mode';
  static const String keepScreenOnKey = 'keep_screen_on';
  static const String showStatusKey = 'show_status';
  static const String showProgressKey = 'show_progress';

  // 个人信息
  static const String authorName = 'KBchulan';
  static const String authorEmail = '18737519552@163.com';
  static const String githubUrl = 'https://github.com/KBchulan/lightNovel';

  // 更新检查
  static const String updateCheckUrl =
      'https://api.github.com/repos/KBchulan/lightNovel/releases/latest';
  static const Duration updateCheckInterval = Duration(days: 1);
}
