import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/hive_service.dart';

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
