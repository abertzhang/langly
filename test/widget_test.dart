// 主题模式链路测试，刻意拆成两层：
//   - testWidgets：验证 Riverpod → MaterialApp 深浅主题（UI 层）；
//   - 普通 test  ：用 ProviderContainer 验证 Notifier → Hive 落盘 → 冷启动读回。
// 之所以不把 Hive 初始化放进 setUp 再跑 testWidgets：
// 实测该组合会让 flutter_tester 挂住（testWidgets 跑在 FakeAsync 里，
// 而 Hive.openBox 的文件 IO Future 在这个 zone 里等不到推进）。
// 拆开后两层链路都覆盖，且都不依赖平台通道。

import 'dart:io' show Directory;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:langly/core/storage/hive_service.dart';
import 'package:langly/core/theme/theme_mode_provider.dart';
import 'package:langly/main.dart';

/// 有限帧推进：ScreenUtilPlusInit 会自动重建，
/// pumpAndSettle() 可能一直等不到「没有新帧」的状态，所以固定推进两帧。
/// 注意不能再加 Future.delayed —— FakeAsync 里没有 pump 推进它就会挂死。
Future<void> pumpSafely(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('三档主题切换让深浅主题即时生效', (tester) async {
    // 这里不初始化 Hive：HiveService 会自动走降级路径返回默认值，
    // 顺带验证了「本地存储不可用时 App 依然能启动」。
    // ProviderScope 必须由测试自己提供，正式入口是在 main() 里包的。
    await tester.pumpWidget(const ProviderScope(child: LanglyApp()));
    await pumpSafely(tester);

    expect(find.text('当前选择：跟随系统'), findsOneWidget);

    // 切到深色。
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<ThemeMode>),
        matching: find.text('深色'),
      ),
    );
    await pumpSafely(tester);

    expect(find.text('当前选择：深色'), findsOneWidget);
    // 这行来自 Theme.of(context).brightness，证明 darkTheme 真的被套上了。
    expect(find.text('实际生效：深色'), findsOneWidget);

    // 再切回浅色，确认双向切换都正常。
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<ThemeMode>),
        matching: find.text('浅色'),
      ),
    );
    await pumpSafely(tester);

    expect(find.text('当前选择：浅色'), findsOneWidget);
    expect(find.text('实际生效：浅色'), findsOneWidget);
  });

  test('Notifier 写入 Hive，冷启动能从 Box 读回', () async {
    // 测试进程里没有 path_provider 插件实现，所以不用 Hive.initFlutter()，
    // 改用纯 dart:io 的 Hive.init(临时目录)，效果等价。
    final dir = await Directory.systemTemp.createTemp('langly_hive_test_');
    addTearDown(() async {
      await Hive.close();
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    Hive.init(dir.path);
    await Hive.openBox(HiveService.settingsBoxName);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 首次启动默认跟随系统。
    expect(container.read(themeModeProvider), ThemeMode.system);

    // 改状态 → Notifier 会先更新 state，再异步写 Hive。
    container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    // 普通 test 是真实 async，可以安全等待落盘的 Future 走完。
    await Future<void>.delayed(Duration.zero);
    expect(
      Hive.box(HiveService.settingsBoxName).get(HiveService.themeModeKey),
      'dark',
    );
    expect(HiveService.readThemeMode(), ThemeMode.dark);

    // 新建一个 container 模拟冷启动：build() 应重新从 Hive 读到 dark。
    final coldStart = ProviderContainer();
    addTearDown(coldStart.dispose);
    expect(coldStart.read(themeModeProvider), ThemeMode.dark);

    // 再验证 cycle() 的三档循环顺序。
    final notifier = container.read(themeModeProvider.notifier);
    notifier.cycle(); // dark -> system
    expect(container.read(themeModeProvider), ThemeMode.system);
    notifier.cycle(); // system -> light
    expect(container.read(themeModeProvider), ThemeMode.light);
  });
}
