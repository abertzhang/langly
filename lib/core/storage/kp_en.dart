import 'dart:convert' show jsonDecode;

/// `kp_en` 表的一行 = 一条英语知识点。
///
/// 数据来源：`asset/langly.db`（由 `doc/kp/en_kp.json` 生成，表结构见
/// `doc/kp/kp_en_schema.sql`）。表里的 tag / examples / synonym_points /
/// antonym_points / extended_points 五个字段在 SQLite 里是「JSON 数组字符串」，
/// 这里在模型层统一还原成 `List<String>`，页面不需要知道底层存的是 TEXT。
///
/// 多行文本（translation_content / explanation / key_point）保留原始的 \n，
/// 由 UI 决定展示几行。
class KpEn {
  const KpEn({
    required this.id,
    required this.pointId,
    required this.pointContent,
    required this.tags,
    required this.translationLang,
    required this.translationContent,
    required this.examples,
    required this.explanation,
    required this.synonymPoints,
    required this.antonymPoints,
    required this.extendedPoints,
    required this.keyPoint,
  });

  final int id;
  final String pointId;
  final String pointContent;
  final List<String> tags;
  final String translationLang;
  final String translationContent;
  final List<String> examples;
  final String explanation;
  final List<String> synonymPoints;
  final List<String> antonymPoints;
  final List<String> extendedPoints;
  final String keyPoint;

  /// 把 `db.query()` 返回的一行 Map 转成模型。
  ///
  /// 字段缺失 / 类型不符 / JSON 损坏都走空值降级，
  /// 不让一条脏数据把整个首页搞崩（种子库可能被手工编辑过）。
  factory KpEn.fromRow(Map<String, Object?> row) {
    return KpEn(
      id: (row['id'] as num?)?.toInt() ?? 0,
      pointId: _asString(row['point_id']),
      pointContent: _asString(row['point_content']),
      tags: _decodeList(row['tag']),
      translationLang: _asString(row['translation_lang']),
      translationContent: _asString(row['translation_content']),
      examples: _decodeList(row['examples']),
      explanation: _asString(row['explanation']),
      synonymPoints: _decodeList(row['synonym_points']),
      antonymPoints: _decodeList(row['antonym_points']),
      extendedPoints: _decodeList(row['extended_points']),
      keyPoint: _asString(row['key_point']),
    );
  }

  static String _asString(Object? value) => value is String ? value : '';

  static List<String> _decodeList(Object? raw) {
    if (raw is! String || raw.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <String>[];
      return decoded.map((item) => item.toString()).toList(growable: false);
    } on FormatException {
      // JSON 数组字符串被写坏时退化成空列表，页面仍能正常渲染。
      return const <String>[];
    }
  }
}
