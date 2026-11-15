# -*- coding: utf-8 -*-
"""把 en_kp.xlsx 的首条知识点补充进 en_kp.json（同知识点合并为一条，不重复追加）。

- 现有 en_kp.json 中已有一条 "It's in my blood"（简版），本脚本保留其全部信息，
  再把 Excel 的完整内容合并进去，输出仍是「一条记录」。
- 覆盖前先备份旧文件到 .en_kp.ref/，可逆。
- 多值字段按现有 JSON 习惯用数组；长文本用 \n 分段，由 json.dump 自动转义。
"""

from __future__ import annotations

import json
import re
import shutil
from datetime import datetime
from pathlib import Path

from openpyxl import load_workbook

BASE = Path("/Users/zhangchunhua/project/Remote/repo/langly/doc/kp")
XLSX = BASE / "en_kp.xlsx"
JSON_PATH = BASE / "en_kp.json"
REF = BASE / ".en_kp.ref"


# ---------------------------------------------------------------- 1. 读 Excel
wb = load_workbook(XLSX, data_only=True)
ws = wb["en_kp"]
excel_keys = [c.value for c in ws[1]]
excel_record = {k: ws.cell(row=2, column=i + 1).value for i, k in enumerate(excel_keys)}
assert excel_record["point_content"] == "It's in my blood", excel_record["point_content"]


# ---------------------------------------------------------------- 2. 备份并读旧 JSON
old_data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
if not isinstance(old_data, list):
    raise ValueError("en_kp.json 顶层不是数组，请先人工确认结构")

stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
backup = REF / f"en_kp_before_merge_{stamp}.json"
shutil.copy2(JSON_PATH, backup)

old = next(
    (r for r in old_data if r.get("point_content") == excel_record["point_content"]),
    None,
)
if old is None:
    raise ValueError("未找到同知识点记录，本脚本按「合并」设计，请改用追加逻辑")


# ---------------------------------------------------------------- 3. 工具函数
def merge_unique(*groups):
    """按出现顺序合并多个列表并去重（字符串完全相同才去重）。"""
    out = []
    for group in groups:
        for item in group:
            if item and item not in out:
                out.append(item)
    return out


def numbered_items(text: str):
    """把 Excel 单元格里「1. xxx」的编号列表解析成不带编号的条目。"""
    items = []
    for line in text.split("\n"):
        s = line.strip()
        if not s or s.startswith("（"):
            continue
        items.append(re.sub(r"^\d+\.\s*", "", s))
    return items


def example_pairs(text: str):
    """把 Excel 的「英文例句 + 缩进中文译文」合并成与旧 JSON 一致的单行字符串。"""
    pairs, buf = [], []
    for line in text.split("\n"):
        s = line.strip()
        if not s:
            continue
        if re.match(r"^\d+\.\s", s):
            if buf:
                pairs.append(" ".join(buf))
            buf = [re.sub(r"^\d+\.\s*", "", s)]
        else:
            buf.append(s)
    if buf:
        pairs.append(" ".join(buf))
    return pairs


# ---------------------------------------------------------------- 4. 合并内容
# 近义 / 反义 / 扩展：两版条目人工去重整理，保留差异说明，避免同义条目堆砌
synonyms = [
    "run in the family / It runs in the family. — 家族里代代都有（最贴近，但侧重「一家人」而非个人）",
    "be born with sth / be born to do sth / be a natural — 天生就有 / 天生是这块料",
    "come naturally to sb — 对某人来说毫不费力",
    "be in one's genes / It's in my genes. — 写在基因里（更口语、更「科学」的说法）",
    "have a knack for sth — 有窍门、有天分（程度较轻）",
    "innate/inborn — 天生的、先天的（形容词，偏书面）",
    "second nature — 习以为常（注意：强调后天练到本能，不是天生）",
]
antonyms = [
    "（本习语无严格反义词，以下为语义对立表达）",
    "against one's nature / go against one's nature — 违背本性",
    "be out of character — 不像本人的做派",
    "learned behavior / be an acquired skill — 后天习得、慢慢练出来",
    "an acquired taste — 慢慢才喜欢上的（口味 / 爱好）",
    "learn it from scratch — 从零学起",
    "have no aptitude for sth — 对某事没天分",
    "unnatural — 不自然、非天性（形容词）",
]
extended = [
    "blood is thicker than water / Blood is thicker than water. — 血浓于水",
    "make one's blood boil — 让人怒火中烧",
    "in cold blood — 冷血地、蓄意地（残忍地）",
    "new blood / fresh blood — 新人、新鲜血液",
    "blue blood — 贵族血统",
    "bad blood — 宿怨、嫌隙（积怨）",
    "blood, sweat and tears — 心血与汗水",
    "make one's blood run cold — 吓呆、毛骨悚然",
    "run deep in one's blood — 在我家根深蒂固（It runs deep in my blood.）",
]

explanation = (
    "【概要】" + old["explanation"].strip() + "\n" + excel_record["explanation"].strip()
)
key_point = (
    "【速记】" + old["key_point"].strip() + "\n" + excel_record["key_point"].strip()
)
translation_content = (
    old["translation_content"].strip() + "\n" + excel_record["translation_content"].strip()
)

merged = {
    "id": old.get("id") if old.get("id") is not None else excel_record["id"],
    "point_id": old.get("point_id") or excel_record["point_id"],  # 沿用旧编号，不覆盖
    "point_content": old["point_content"],
    "tag": merge_unique(old.get("tag", []), json.loads(excel_record["tag"])),
    "translation_lang": excel_record["translation_lang"],  # 规范化 BCP-47: zh-cn -> zh-CN
    "translation_content": translation_content,
    "examples": merge_unique(old.get("examples", []), example_pairs(excel_record["examples"])),
    "explanation": explanation,
    "synonym_points": synonyms,
    "antonym_points": antonyms,
    "extended_points": extended,
    "key_point": key_point,
}

assert list(merged) == excel_keys, (list(merged), excel_keys)

# 同知识点替换，不新增记录；其余记录原样保留
new_data = [merged if r is old else r for r in old_data]

JSON_PATH.write_text(
    json.dumps(new_data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
)


# ---------------------------------------------------------------- 5. 校验
check = json.loads(JSON_PATH.read_text(encoding="utf-8"))
rec = check[0]
assert len(check) == len(old_data) == 1
assert list(rec) == excel_keys
assert rec["point_content"] == "It's in my blood"
assert len(rec["examples"]) >= 5 and all(isinstance(x, str) and x.strip() for x in rec["examples"])
assert all(isinstance(rec[k], list) and rec[k] for k in ("tag", "synonym_points", "antonym_points", "extended_points"))
assert all(str(rec[k]).strip() for k in excel_keys)
assert backup.exists()

# 两版信息都没丢：旧例句逐条保留；旧/新近反扩展的关键表达都能在合并结果里找到
must_have = {
    "synonym_points": ["run in the family", "be born", "come naturally", "in one's genes",
                       "knack", "second nature", "innate"],
    "antonym_points": ["against one's nature", "acquired", "from scratch", "no aptitude",
                       "out of character", "unnatural"],
    "extended_points": ["thicker than water", "blood boil", "cold blood", "new blood",
                        "blue blood", "bad blood", "sweat and tears", "run cold", "run deep"],
}
for field, keys in must_have.items():
    blob = "\n".join(rec[field]).lower()
    assert all(k in blob for k in keys), (field, [k for k in keys if k not in blob])

old_blob = {
    "synonym_points": ["it runs in the family", "be born to do", "second nature", "innate", "in my genes"],
    "antonym_points": ["against one's nature", "learned behavior", "unnatural"],
    "extended_points": ["blue blood", "bad blood", "thicker than water", "cold blood", "run cold"],
}
for field, keys in old_blob.items():
    blob = "\n".join(rec[field]).lower()
    assert all(k in blob for k in keys), (field, [k for k in keys if k not in blob])

print("BACKUP", backup.name)
print("JSON  ", JSON_PATH)
print("RECORDS", len(check), "| KEYS", len(rec), "| EXAMPLES", len(rec["examples"]))
print("POINT_ID", rec["point_id"], "| ID", rec["id"], "| LANG", rec["translation_lang"])
print("COUNTS tag/syn/ant/ext", *(len(rec[k]) for k in ("tag", "synonym_points", "antonym_points", "extended_points")))
print("OLD_EXAMPLES_KEPT", all(x in rec["examples"] for x in old["examples"]))
print("OLD_FIELDS_COVERED", True)
