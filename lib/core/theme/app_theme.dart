import 'package:flutter/material.dart';

/// App 的亮 / 暗两套主题。
///
/// 设计原则：
/// - 只用一份种子色生成两套 ColorScheme，让 Material 3 组件自动适配深浅，
///   不逐个手写组件颜色，后续加页面也不会出现「某个控件没跟着变」的漏网之鱼；
/// - 页面里需要强调的地方一律从 Theme.of(context).colorScheme 取色，
///   不写死 Colors.white / Colors.black，否则深色模式下会瞎。
class AppTheme {
  AppTheme._();

  /// 品牌橙：取自应用图标主色，也和 web/manifest.json 的 theme_color 一致。
  static const Color brandSeed = Color(0xFFF96C39);

  /// 浅色主题。
  static ThemeData get light => _build(Brightness.light);

  /// 深色主题。
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: brandSeed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // 显式指定页面底色：浅色近白、深色深灰，切主题时对比最直观。
      scaffoldBackgroundColor: scheme.surface,
      // AppBar 跟随页面底色，不做浮起的阴影块。
      // 这里刻意不用 AppBarTheme：Flutter 3.5x 起它已改名 AppBarThemeData，
      // 与其跟着版本改，不如在 HomePage 里直接用 colorScheme 上色。
    );
  }
}
