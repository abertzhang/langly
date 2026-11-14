import 'package:flutter/material.dart' show ThemeMode;
import 'package:hive_flutter/hive_flutter.dart';

/// Hive 本地存储服务（轻量 KV，适合放设置项与用户偏好）。
///
/// 职责边界：
/// - 只负责「settings」这一个 Box 的初始化与主题模式读写；
/// - 后续像每日上限、当前学习语言这类偏好，都往这个 Box 里加 key 即可；
/// - 业务主数据（知识点、讲解、复习流水）按 doc/sqlite.md 的设计走 sqflite，
///   不放进 Hive，避免两套存储职责混在一起。
class HiveService {
  // 私有构造，这个类只提供静态方法，不允许被实例化。
  HiveService._();

  /// Box 名称：所有 App 设置项都放这里。
  static const String settingsBoxName = 'settings';

  /// 主题模式对应的 key。
  static const String themeModeKey = 'themeMode';

  /// 首次安装 / 数据被清空时的默认值：跟随系统。
  static const ThemeMode defaultThemeMode = ThemeMode.system;

  /// 在 main() 里、runApp() 之前调用。
  ///
  /// Hive.initFlutter() 会通过 path_provider 拿到应用文档目录，
  /// 属于插件通道调用，因此 main() 里必须先 WidgetsFlutterBinding.ensureInitialized()。
  /// openBox 提前打开后，后面所有读写都可以用同步的 Hive.box() 完成。
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(settingsBoxName)) {
      await Hive.openBox(settingsBoxName);
    }
  }

  /// 同步读取主题模式。
  ///
  /// 存的是枚举名字符串（'system' / 'light' / 'dark'），不是索引：
  /// 这样以后就算枚举顺序调整，老数据也不会串位。
  /// 如果 Box 没打开（比如单元测试环境还没初始化），直接返回默认值，
  /// 保证 App 不会因为本地存储异常而崩在启动阶段。
  static ThemeMode readThemeMode() {
    if (!Hive.isBoxOpen(settingsBoxName)) return defaultThemeMode;

    final stored = Hive.box(settingsBoxName).get(themeModeKey);
    if (stored is! String) return defaultThemeMode;

    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => defaultThemeMode,
    );
  }

  /// 异步写入主题模式。
  ///
  /// 调用方（ThemeModeNotifier）会先更新内存里的 state 让 UI 立刻刷新，
  /// 再「发后不理」地落盘，磁盘 IO 不会卡住主题切换动画。
  static Future<void> writeThemeMode(ThemeMode mode) async {
    if (!Hive.isBoxOpen(settingsBoxName)) return;
    await Hive.box(settingsBoxName).put(themeModeKey, mode.name);
  }
}
