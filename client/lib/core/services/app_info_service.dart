class AppInfo {
  static const String appName = 'LightNovel';
  static const String version = '1.0.0';
  static const String buildNumber = '1';
  static const String packageName = 'com.example.lightnovel';
  
  // 获取应用版本信息
  static String get versionWithBuild => '$version+$buildNumber';
  
  // 获取完整的应用信息
  static Map<String, String> get fullInfo => {
    'appName': appName,
    'version': version,
    'buildNumber': buildNumber,
    'packageName': packageName,
    'versionWithBuild': versionWithBuild,
  };
} 