# -*- coding: utf-8 -*-
"""把 .en_kp.ref/batches/*.json 里的知识点合并进 en_kp.json（按知识点去重，不重复追加）。

用法：
    python3 .en_kp.ref/merge_batches.py

规则：
- 批次文件按文件名排序；
- point_content 归一化后（小写、去首尾标点、压缩空格）相同的记录只保留最早的一条；
- id 从 1 连续递增，point_id 依次为 KP-001、KP-002 …（与集号无关）；
- 字段顺序固定为 en_kp 表头顺序；
- 覆盖前先备份到 .en_kp.ref/en_kp_before_merge_<时间戳>.json。
"""

from __future__ import annotations

import json
import re
import shutil
from datetime import datetime
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
JSON_PATH = BASE / "en_kp.json"
REF = BASE / ".en_kp.ref"
BATCH_DIR = REF / "batches"

FIELDS = [
    "id",
    "point_id",
    "point_content",
    "tag",
    "translation_lang",
    "translation_content",
    "examples",
    "explanation",
    "synonym_points",
    "antonym_points",
    "extended_points",
    "key_point",
]


def norm(text: str) -> str:
    """归一化用于去重：小写、去掉中英句读符号（含 sb./sth. 缩写点、逗号）、压缩空格。"""
    s = text.lower().strip()
    s = re.sub(r"[.,!?;:。，！？；：、/]", "", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


def main() -> None:
    existing = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    if not isinstance(existing, list):
        raise ValueError("en_kp.json 顶层不是数组")

    kept, seen, added = [], {}, 0
    for record in existing:
        key = norm(record["point_content"])
        if key in seen:
            continue
        seen[key] = True
        kept.append(record)

    for path in sorted(BATCH_DIR.glob("*.json")):
        records = json.loads(path.read_text(encoding="utf-8"))
        for record in records:
            key = norm(record["point_content"])
            if key in seen:
                continue
            seen[key] = True
            kept.append({f: record[f] for f in FIELDS if f in record})
            added += 1

    ordered = []
    for i, record in enumerate(kept, start=1):
        record["id"] = i
        record["point_id"] = f"KP-{i:03d}"
        ordered.append({f: record[f] for f in FIELDS})

    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    shutil.copy2(JSON_PATH, REF / f"en_kp_before_merge_{stamp}.json")
    JSON_PATH.write_text(
        json.dumps(ordered, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    print(f"existing={len(existing)} added={added} total={len(ordered)}")


if __name__ == "__main__":
    main()
