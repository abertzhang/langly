import 'dart:io' show File;

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'kp_en.dart';

/// SQLite 读取层：把预置种子库 `asset/langly.db` 复制到应用可写目录后查询。
///
/// 数据流（对应项目里已经跑通的链路）：
///   doc/kp/en_kp.json → doc/kp/.en_kp.ref/build_db.py → asset/langly.db
///   → 首次启动复制到可写目录 → sqflite 查询 → Riverpod → 首页。
///
/// 职责边界：
/// - 这里只做「打开 + 读取」，后续写复习记录 / 讲解流水时再扩展写入方法；
/// - Hive 仍然只管 settings 等轻量偏好，两套存储不混用（见 hive_service.dart）。
///
/// 平台支持：iOS / Android 走 sqflite 自带的联邦插件（sqflite_darwin /
/// sqflite_android），不需要任何额外的 ffi / sqlite3 依赖。
/// ⚠️ Web 与桌面端暂不支持：dart:io 的 File 在 Web 上不可用，项目也没有
/// macos/ / linux/ / windows/ runner。将来若要补桌面或 Web，需要单独接入
/// ffi / ffi_web 实现；注意 sqflite_common_ffi 依赖的 sqlite3 带有
/// native assets build hook，会拖慢甚至卡住 iOS 构建（见 pubspec.yaml 注释）。
class SqliteService {
  SqliteService._();

  /// 全局单例：数据库句柄要复用，不能每读一次就 open 一次。
  static final SqliteService instance = SqliteService._();

  /// SQLite 没有「库名」概念，一个文件就是一个库；langly 即 langly.db。
  static const String dbName = 'langly.db';

  /// pubspec.yaml 的 flutter.assets 已注册这个预置库。
  static const String assetDbPath = 'asset/langly.db';

  /// 表名按用户指定，与 doc/sqlite.md 草稿的 en_kp / 正式 knowledge_points 不同。
  static const String tableName = 'kp_en';

  /// 缓存「正在打开 / 已打开」的 Future：并发读取时只复制、打开一次。
  Future<Database>? _opening;

  /// 在 main() 里、runApp() 之前预热。
  ///
  /// 这里刻意不吞异常：由 main() 统一 catch 并打印，首页的 FutureProvider
  /// 也会自己兜一次（失败时 _opening 已清空，可以重试）。
  Future<void> init() async {
    await _database();
  }

  Future<Database> _database() {
    final pending = _opening;
    if (pending != null) return pending;
    final future = _openInternal();
    _opening = future;
    return future;
  }

  Future<Database> _openInternal() async {
    try {
      // ① 拿可写目录：asset 是只读的，SQLite 需要能写 journal / WAL 的目录。
      //    getDatabasesPath() 由 sqflite 的原生插件提供，iOS / Android 下
      //    返回的都是 App 沙盒内的可写路径，无需 path_provider 再绕一层。
      final dbDir = await getDatabasesPath();
      final dbPath = p.join(dbDir, dbName);

      // ② 首次启动（或用户清过数据）：把预置库整包复制过去。
      //    之后用户产生的数据都落在可写目录，asset 永远不被改写。
      if (!await databaseExists(dbPath)) {
        final data = await rootBundle.load(assetDbPath);
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(dbPath).writeAsBytes(bytes, flush: true);
      }

      // ③ 打开数据库；singleInstance 避免多处重复打开同一个文件。
      //    当前只读查询，但不设 readOnly，方便后续直接扩展写入方法。
      return await openDatabase(dbPath, singleInstance: true);
    } catch (_) {
      // 打开失败不缓存 Future，否则后续读取会一直拿到同一个错误。
      _opening = null;
      rethrow;
    }
  }

  /// 第一条知识点（按自增 id 升序）；空表返回 null。
  Future<KpEn?> fetchFirstKp() async {
    final db = await _database();
    final rows = await db.query(tableName, orderBy: 'id ASC', limit: 1);
    if (rows.isEmpty) return null;
    return KpEn.fromRow(rows.first);
  }

  /// 表内总条数：首页用它证明「整库都导进来了」，而不只是第一条。
  Future<int> countKp() async {
    final db = await _database();
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $tableName');
    final value = rows.first['c'];
    return value is int ? value : int.tryParse('$value') ?? 0;
  }
}
