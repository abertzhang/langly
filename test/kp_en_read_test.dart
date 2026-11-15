// 知识点读取链路的两层验证（刻意不依赖平台插件通道）：
//   - 普通 test    ：校验 asset/langly.db 是真正的 SQLite 3 文件，并用
//                    en_kp.json 首条构造「与 db.query 同形状」的一行，
//                    验证 KpEn.fromRow 的字段映射 + JSON 数组还原；
//   - testWidgets  ：用 overrideWithValue 注入 AsyncData，
//                    验证首页 data 分支真的把第一条数据画出来。
// ⚠️ 这里不引入 sqflite_common_ffi：它依赖 sqlite3 的 native assets
//    build hook，会在 iOS 构建时抢锁导致编译失败（详见 pubspec.yaml）。
//    SQL 层的正确性由 doc/kp/.en_kp.ref/build_db.py 的逐字段 round-trip
//    校验 + sqlite3 CLI 查询保证，测试只负责 Dart 侧的模型映射。

import 'dart:convert' show jsonDecode, jsonEncode, utf8;
import 'dart:io' show File;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langly/core/storage/kp_en.dart';
import 'package:langly/features/home/first_kp_provider.dart';
import 'package:langly/main.dart';

/// 与 widget_test.dart 一致：ScreenUtilPlusInit 会自动重建，
/// 不能 pumpAndSettle，固定推进两帧即可。
Future<void> pumpSafely(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  test('asset/langly.db 与 en_kp.json 首条记录能被 KpEn 完整还原', () async {
    final dbFile = File('asset/langly.db').absolute;
    expect(dbFile.existsSync(), isTrue, reason: '缺少 asset/langly.db');

    // 只读文件头：SQLite 3 的固定魔数是 "SQLite format 3\0"。
    final raf = await dbFile.open();
    final head = await raf.read(16);
    await raf.close();
    expect(head, utf8.encode('SQLite format 3\u0000'));

    // 权威数据源是 en_kp.json；把它变成 db.query() 返回的行形状：
    // 5 个数组字段在 SQLite 里存的是 JSON 数组字符串 TEXT。
    final source = jsonDecode(
      File('doc/kp/en_kp.json').readAsStringSync(),
    ) as List<dynamic>;
    expect(source.length, 825, reason: '种子库记录数应与 JSON 一致');

    final first = source.first as Map<String, dynamic>;
    final row = <String, Object?>{
      for (final entry in first.entries)
        entry.key: entry.value is List ? jsonEncode(entry.value) : entry.value,
    };

    final kp = KpEn.fromRow(row);
    expect(kp.id, 1);
    expect(kp.pointId, 'KP-001');
    expect(kp.pointContent, "It's in my blood");
    expect(kp.translationLang, 'zh-CN');
    expect(kp.tags, isNotEmpty);
    expect(kp.examples.length, greaterThanOrEqualTo(5));
    expect(kp.synonymPoints, isNotEmpty);
    expect(kp.antonymPoints, isNotEmpty);
    expect(kp.extendedPoints, isNotEmpty);
    expect(kp.keyPoint, isNotEmpty);

    // 种子库被手工改坏时模型要降级而不是让首页崩掉。
    expect(
      KpEn.fromRow(<String, Object?>{'tag': '{not json', 'id': null}).tags,
      isEmpty,
    );
  });

  testWidgets('首页知识点卡片展示 kp_en 第一条数据', (tester) async {
    final kp = KpEn(
      id: 1,
      pointId: 'KP-001',
      pointContent: "It's in my blood",
      tags: const ['习语', '家庭传承'],
      translationLang: 'zh-CN',
      translationContent: '这是天生的；骨子里就有',
      examples: const ['Cooking is in my blood. 做饭是刻在骨子里的。'],
      explanation: '句型 Sth is in one\'s blood.',
      synonymPoints: const ['run in the family'],
      antonymPoints: const ['learned behavior'],
      extendedPoints: const ['blue blood'],
      keyPoint: '天生或家传的特质，用 X is in one\'s blood。',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firstKpProvider.overrideWithValue(
            AsyncData<FirstKpSnapshot>(FirstKpSnapshot(point: kp, total: 825)),
          ),
        ],
        child: const LanglyApp(),
      ),
    );
    await pumpSafely(tester);

    expect(find.text('SQLite 读取 · kp_en 表'), findsOneWidget);
    expect(find.text("It's in my blood"), findsOneWidget);
    expect(find.text('KP-001'), findsOneWidget);
    expect(find.text('共 825 条'), findsOneWidget);
    expect(find.text('这是天生的；骨子里就有'), findsOneWidget);
    // 下面三张原有卡片仍在，说明新卡片没有挤掉旧内容。
    expect(find.text('当前选择：跟随系统'), findsOneWidget);
  });
}
