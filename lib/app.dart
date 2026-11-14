import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/home/home_page.dart';

/// App 根组件。
///
/// 用 ConsumerWidget 而不是 StatelessWidget，是为了能 ref.watch 主题模式：
/// 用户在首页切换模式 → provider 状态变化 → MaterialApp 重建 →
/// theme / darkTheme / themeMode 三个参数立刻生效。
class LanglyApp extends ConsumerWidget {
  const LanglyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ScreenUtilPlusInit(
      // 设计稿基准尺寸，来自 doc/mockplus_ai_prompt.md（390×844）。
      // 所有 .w / .h / .r / .sp 都按这个基准等比换算。
      designSize: const Size(390, 844),
      // 文字按宽度缩放，且不小于系统最小字号，避免小屏上文字被压得过小。
      minTextAdapt: true,
      // 分屏 / 多窗口时按当前窗口尺寸重算，而不是拿整块屏幕尺寸。
      splitScreenMode: true,
      // child 只构建一次：主题切换时 builder 重建，但首页不会跟着重复创建。
      child: const HomePage(),
      builder: (context, child) {
        return MaterialApp(
          title: 'Langly',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: child,
        );
      },
    );
  }
}
