import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'core/storage/hive_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/home/home_page.dart';

/// 设计稿基准尺寸（逻辑点 dp）。
///
/// 来源：1206 × 2622 的物理像素稿按 @3x 换算 → 402 × 874 dp
/// （对应 iPhone 16 Pro 一类的 6.3 英寸机型）。
/// 所有 .w / .h / .r / .sp 都以这个尺寸为分母等比换算，
/// 改这里一处即可，不需要去动每个页面的数值。
const Size kDesignSize = Size(402, 874);

/// 应用入口。
///
/// 启动顺序有讲究：
/// 1. ensureInitialized —— Hive.initFlutter() 会走 path_provider 插件通道，
///    绑定没初始化就调用会抛 Binding has not yet been initialized；
/// 2. HiveService.init() —— 打开 settings Box，之后主题模式可以同步读取；
/// 3. ProviderScope 包住整个 App —— Riverpod 的所有 provider 都挂在它下面，
///    少了这一层，ref.watch 会直接报「No ProviderScope found」。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const ProviderScope(child: LanglyApp()));
}

class LanglyApp extends ConsumerWidget {
  const LanglyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ScreenUtilPlusInit(
      // 设计稿基准：402×874 dp（1206×2622 物理像素 @3x）。
      // 详见文件顶部的 kDesignSize 注释。
      designSize: kDesignSize,
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
