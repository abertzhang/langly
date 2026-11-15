# -*- coding: utf-8 -*-
"""由 doc/kp/en_kp.json 生成 / 同步 SQLite 数据库 asset/langly.db 的 kp_en 表。

用法：
    python3 build_db.py              # 幂等 upsert（按 point_id 覆盖同编号记录）
    python3 build_db.py --replace    # 先清空 kp_en，再按 JSON 全量重建（真正的镜像）

JSON 是权威数据源；数组字段序列化成 JSON 数组字符串存 TEXT，其余文本原样保留（含 \n）。
"""

from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path

ROOT = Path("/Users/zhangchunhua/project/Remote/repo/langly")
JSON_PATH = ROOT / "doc/kp/en_kp.json"
DDL_PATH = ROOT / "doc/kp/kp_en_schema.sql"
DB_PATH = ROOT / "asset/langly.db"

# 与 en_kp.json / kp_en 表列顺序严格一致
FIELDS = [
    "id", "point_id", "point_content", "tag", "translation_lang",
    "translation_content", "examples", "explanation", "synonym_points",
    "antonym_points", "extended_points", "key_point",
]
ARRAY_FIELDS = {"tag", "examples", "synonym_points", "antonym_points", "extended_points"}


def load_records() -> list[dict]:
    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    if not isinstance(data, list) or not data:
        raise ValueError("en_kp.json 顶层必须是非空数组")
    for i, rec in enumerate(data):
        missing = [f for f in FIELDS if f not in rec]
        extra = [k for k in rec if k not in FIELDS]
        if missing or extra:
            raise ValueError(f"第 {i + 1} 条字段不匹配: 缺 {missing}, 多 {extra}")
        if rec["id"] is None:
            raise ValueError(f"第 {i + 1} 条 id 为空")
        for f in ARRAY_FIELDS:
            if not isinstance(rec[f], list):
                raise ValueError(f"第 {i + 1} 条 {f} 应为数组，实际 {type(rec[f]).__name__}")
    return data


def encode(field: str, value):
    """把 JSON 值映射成 SQLite 列值。"""
    if field in ARRAY_FIELDS:
        return json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    if field == "id":
        return int(value)
    return str(value)


def decode(field: str, value):
    """读回时还原成 JSON 的同型值，用于逐字段比对。"""
    if field in ARRAY_FIELDS:
        return json.loads(value)
    if field == "id":
        return int(value)
    return value


def main() -> None:
    replace = "--replace" in sys.argv[1:]
    records = load_records()
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(DB_PATH)
    try:
        conn.execute("PRAGMA foreign_keys = ON")
        conn.executescript(DDL_PATH.read_text(encoding="utf-8"))

        columns = ", ".join(FIELDS)
        placeholders = ", ".join("?" for _ in FIELDS)
        updates = ", ".join(
            f"{f}=excluded.{f}" for f in FIELDS if f not in ("id", "point_id")
        )
        upsert = (
            f"INSERT INTO kp_en ({columns}) VALUES ({placeholders}) "
            f"ON CONFLICT(point_id) DO UPDATE SET {updates}"
        )

        with conn:
            if replace:
                conn.execute("DELETE FROM kp_en")
            for rec in records:
                conn.execute(upsert, tuple(encode(f, rec[f]) for f in FIELDS))

        # ---------------- 校验：结构 + 逐字段回读 + 完整性 ----------------
        info = conn.execute("PRAGMA table_info(kp_en)").fetchall()
        col_names = [r[1] for r in info]
        assert col_names == FIELDS, (col_names, FIELDS)

        rows = conn.execute(f"SELECT {columns} FROM kp_en ORDER BY id").fetchall()
        assert len(rows) == len(records), (len(rows), len(records))

        by_point = {r[1]: r for r in rows}
        for rec in records:
            row = by_point[rec["point_id"]]
            for i, f in enumerate(FIELDS):
                assert decode(f, row[i]) == rec[f], (rec["point_id"], f)

        integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
        assert integrity == "ok", integrity

        print("DB      ", DB_PATH)
        print("MODE    ", "replace (full mirror)" if replace else "upsert (by point_id)")
        print("TABLE   ", "kp_en", "| COLUMNS", len(col_names), "| ROWS", len(rows))
        print("SCHEMA  ", ", ".join(f"{r[1]}:{r[2]}" for r in info))
        first = rows[0]
        print("FIRST   ", first[1], first[2], "| lang", first[4],
              "| examples", len(json.loads(first[6])), "| tags", len(json.loads(first[3])))
        print("INTEGRITY", integrity, "| JSON_ROUNDTRIP", True)
    finally:
        conn.close()


if __name__ == "__main__":
    main()
