import 'dart:async' show unawaited;

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/hive_service.dart';

/// 全局主题模式状态：system / light / dark 三档。
///
/// 这里是 Riverpod 3 的手写写法（不引入 riverpod_generator / build_runner，
/// 项目初期少一套代码生成链路）：
///   `NotifierProvider<NotifierT, ValueT>(NotifierT.new)`
/// UI 侧用 ref.watch(themeModeProvider) 读状态，
/// 用 ref.read(themeModeProvider.notifier) 拿控制器改状态。
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// 主题模式控制器：负责「内存状态」与「Hive 落盘」两件事。
class ThemeModeNotifier extends Notifier<ThemeMode> {
  /// build() 返回初始状态，会在 provider 第一次被读取时执行。
  @override
  ThemeMode build() => HiveService.readThemeMode();

  /// 设置指定模式：先改内存（UI 立即重建），再异步写 Hive。
  void setMode(ThemeMode mode) {
    if (state == mode) return;
    state = mode;
    // unawaited 明确表达「发后不理」，避免 analyzer 提示未处理的 Future。
    unawaited(HiveService.writeThemeMode(mode));
  }

  /// 给 AppBar 的快捷按钮用：跟随系统 → 浅色 → 深色 → 跟随系统 循环。
  void cycle() {
    const order = <ThemeMode>[
      ThemeMode.system,
      ThemeMode.light,
      ThemeMode.dark,
    ];
    final next = (order.indexOf(state) + 1) % order.length;
    setMode(order[next]);
  }
}
