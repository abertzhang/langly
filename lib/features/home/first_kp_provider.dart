import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/kp_en.dart';
import '../../core/storage/sqlite_service.dart';

/// 首页卡片需要的两样东西：第一条知识点 + 库内总数。
///
/// 拆成一个快照对象，是为了让 UI 只 watch 一个 provider，
/// 不会出现「知识点先渲染、总数后跳一下」的两次闪动。
class FirstKpSnapshot {
  const FirstKpSnapshot({required this.point, required this.total});

  final KpEn? point;
  final int total;
}

/// 首页数据源：从 kp_en 表取第一条记录。
///
/// main() 已经预热过数据库；这里仍走 SqliteService 的单例 Future，
/// 即使预热失败（或单元测试里没走 main），也会在这里再试一次。
/// 异常由 Riverpod 转成 AsyncError，首页有对应的降级展示，不会白屏 / 红屏。
final firstKpProvider = FutureProvider<FirstKpSnapshot>((ref) async {
  final service = SqliteService.instance;
  final point = await service.fetchFirstKp();
  final total = await service.countKp();
  return FirstKpSnapshot(point: point, total: total);
});
