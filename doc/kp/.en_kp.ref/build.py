# -*- coding: utf-8 -*-
"""Langly · en_kp 英语知识点主表生成脚本（openpyxl 直写，一次性建表）。"""

from __future__ import annotations

import unicodedata

try:
    import openpyxl
except ImportError:
    import subprocess
    import sys

    subprocess.check_call([sys.executable, "-m", "pip", "install", "--quiet", "openpyxl>=3.1.0"])
    import openpyxl

from openpyxl import Workbook
from openpyxl.comments import Comment
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter

OUTPUT = "/Users/zhangchunhua/project/Remote/repo/langly/doc/kp/en_kp.xlsx"


def xl_color(css_hex: str) -> str:
    """CSS #RRGGBB -> openpyxl ARGB 字符串。"""
    value = css_hex.removeprefix("#").upper()
    if len(value) != 6:
        raise ValueError(f"Expected #RRGGBB, got: {css_hex}")
    return "FF" + value


# 项目色值：品牌橙 #F96C39，橙底文字用深可可 #3A2A20（不用白字）
XL_ORANGE = xl_color("#F96C39")
XL_COCOA = xl_color("#3A2A20")
XL_PAPER = xl_color("#FFF8F4")
XL_WHITE = xl_color("#FFFFFF")
XL_BORDER = xl_color("#EBDCD2")
XL_TEXT = xl_color("#2B2B2B")
XL_MUTED = xl_color("#7A6558")

THIN = Side(style="thin", color=XL_BORDER)
CELL_BORDER = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)
HEADER_BORDER = Border(bottom=Side(style="thin", color=XL_COCOA))


# ---------------------------------------------------------------- 字段定义
# field = SQLite 列名（来自 doc/sqlite.md「Table-en_kp-知识点」）
# display / meaning = 用户给定的显示值与含义（原表空缺处做了合理补全）
# spec = 后续持续录入时的填写规范
FIELDS = [
    dict(
        field="id",
        display="ID",
        meaning="系统自动递增id",
        spec="系统自动递增整数，从 1 起；导入 SQLite 时可留空由 rowid 生成。",
        value=1,
        width=8,
    ),
    dict(
        field="point_id",
        display="Point ID/知识点编号",
        meaning="知识点的业务编号，用于跨库/导出引用",
        spec="业务编号 EN-KP-4 位流水（本行为 EN-KP-0001）；新增知识点顺序递增、不复用，与 id 相互独立。",
        value="EN-KP-0001",
        width=16,
    ),
    dict(
        field="point_content",
        display="Knowledge Point/知识点",
        meaning="知识点内容",
        spec="目标语言原文（词组 / 句子 / 语法点），保持原拼写与标点；一行一个可讲清的最小知识点。",
        value="It's in my blood",
        width=24,
    ),
    dict(
        field="tag",
        display="Tag",
        meaning="相关主题['']（数组）",
        spec='JSON 数组字符串，如 ["习语","家庭传承"]；元素对应 tag 表的 name；无标签写 []。',
        value='["习语","家庭传承","天赋能力","blood 相关表达"]',
        width=30,
    ),
    dict(
        field="translation_lang",
        display="Translation Language/翻译语言",
        meaning="翻译语言",
        spec="BCP-47 语言代码，对应 lang.lang_code（en / ja / zh-CN / es …）；表示 translation_content 所用语言，不是所学语言。",
        value="zh-CN",
        width=18,
    ),
    dict(
        field="translation_content",
        display="Translation/翻译内容",
        meaning="翻译内容",
        spec="知识点的译文 / 中文释义；可给直译 + 自然译法，多条用换行分隔。",
        value="""刻在骨子里的；与生俱来的、祖传的
（指某种能力、爱好或性情来自家族、从小耳濡目染，几乎成了本能）
自然译法：这是天生的 / 我们家祖传的 / 我骨子里就爱这个""",
        width=36,
    ),
    dict(
        field="examples",
        display="举例",
        meaning="至少5句子举例",
        spec="至少 5 个例句；每句「英文例句 + 中文译文」成对，按 1./2. 编号，尽量覆盖不同人称与场景。",
        value="""1. I grew up in my dad's kitchen — cooking is in my blood.
   我在我爸的厨房里长大，做饭是刻在骨子里的。
2. Both her parents are musicians, so music is in her blood.
   她父母都是音乐人，音乐天赋对她来说是与生俱来的。
3. He never had a single lesson; sailing is just in his blood.
   他一节课都没上过，航海就像天生会一样。
4. I walked away from the stage for a year, but performing is in my blood.
   我离开舞台整整一年，可表演早长在我骨子里了。
5. "Why are you so good with kids?" "Teaching is in my blood — three generations of teachers."
   「你怎么这么会带孩子？」「教书是我们家的老本行，三代人都是老师。」
6. She says gardening is in her blood, not something she picked up from a book.
   她说园艺是骨子里带来的，不是从书上学来的。""",
        width=58,
    ),
    dict(
        field="explanation",
        display="Explanation/知识点讲解",
        meaning="知识点讲解",
        spec="费曼式讲解：一句话定义 → 结构 → 语域语气 → 用法 → 易错点 → 讲给别人听；用自己的话，不堆术语。",
        value="""【一句话】be in one's blood = 某种本事、热爱或性情感像是随血统带来的，天生就有、不用刻意学。
【结构】X + be + in + 形容词性物主代词 + blood。X 常是抽象名词（music / cooking / teaching），也可用 it 代指上文；主语变，物主代词跟着变：Music is in her blood. / It's in my blood.
【语域与语气】口语、中性偏正式；多带自豪或「改不掉」的宿命感，几乎只用于褒义。常用来回答「你怎么这么擅长 / 这么着迷」。
【怎么用】解释天赋、家族传统、长期爱好；前后常接 because / so / three generations… 交代来源。
【易错】① 不能说 in the blood / in my bloods：blood 前必须是物主代词，且不加冠词、不用复数。② 不能按字面译成「在我的血里」。③ It's in my blood 里的 it 必须指代上文提过的那件事，不能凭空出现。
【讲给别人听】「我家三代都干这个，我从小泡在里面，不用教就会——不是我练得多，是它本来就长在我身上。」""",
        width=58,
    ),
    dict(
        field="synonym_points",
        display="Synonym Points/近义知识点",
        meaning="近义知识点",
        spec="近义知识点编号逐条列；写「表达 + 与本条的差别」，别只给一串同义词。",
        value="""1. run in the family — 家族里代代都有（最贴近，但侧重「一家人」而非个人）
2. be born with sth / be a natural — 天生就有 / 天生是这块料
3. come naturally to sb — 对某人来说毫不费力
4. be in one's genes — 写在基因里（更口语、更「科学」的说法）
5. have a knack for sth — 有窍门、有天分（程度较轻）
6. second nature — 习以为常（注意：强调后天练到本能，不是天生）""",
        width=42,
    ),
    dict(
        field="antonym_points",
        display="Antonym Points/反义知识点",
        meaning="反义知识点",
        spec="反义 / 语义对立表达；若无严格反义词，先注明再列对立说法。",
        value="""（本习语无严格反义词，以下是语义对立的常用说法）
1. be an acquired skill / an acquired taste — 后天习得、慢慢练出来或慢慢喜欢上
2. learn it from scratch — 从零学起
3. have no aptitude for sth — 对某事没天分
4. go against one's nature / be out of character — 违背本性、不像本人的做派""",
        width=42,
    ),
    dict(
        field="extended_points",
        display="Extended Points/扩展知识点",
        meaning="扩展知识点",
        spec="扩展知识点：同词根习语、常见搭配、语法延伸、文化背景；编号逐条列。",
        value="""1. blood is thicker than water — 血浓于水
2. make one's blood boil — 让人怒火中烧
3. in cold blood — 冷血地、蓄意地
4. new blood / fresh blood — 新人、新鲜血液
5. blue blood — 贵族血统
6. bad blood — 宿怨、嫌隙
7. blood, sweat and tears — 心血与汗水
8. 搭配延伸：run deep in one's blood（It runs deep in my blood. 这种本事在我家根深蒂固）""",
        width=42,
    ),
    dict(
        field="key_point",
        display="Key Point/关键知识点",
        meaning="关键知识点",
        spec="最该记住的一句：核心义 + 必记结构 + 语用 + 辨析 + 易错；复习时先看这一列。",
        value="""核心：be in one's blood 表示「天赋 / 热爱 / 习性与生俱来、来自家族传承，几乎成了本能」。
必记结构：X is in + 物主代词 + blood（X = 抽象名词或 it）；物主代词与逻辑主语一致，blood 不加冠词、不用复数。
语用：口语、多褒义，解释「为什么这么擅长 / 这么着迷」，常带自豪或「改不掉」的语气。
辨析：in one's blood 说「我身上带着」；run in the family 说「一家人都有」；second nature 是后天练成的，别说混。
易错：不写 in the blood / in my bloods，不字面直译成「在血里」。""",
        width=52,
    ),
]


# ---------------------------------------------------------------- 排版工具
def char_width(ch: str) -> int:
    """全角/中日韩字符按 2 个 Excel 列宽单位计。"""
    return 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1


def wrapped_lines(text, width: int) -> int:
    """按列宽估算 wrapText 之后实际占用的行数（考虑手动换行）。"""
    usable = max(8, width - 3)
    total = 0
    for para in str(text).split("\n"):
        used, lines = 0, 1
        for ch in para:
            w = char_width(ch)
            if used + w > usable:
                lines += 1
                used = 0
            used += w
        total += lines
    return total


def row_height(texts, widths, line_pt: float = 15.0, cap: float = 409.0) -> float:
    needed = max(wrapped_lines(t, w) for t, w in zip(texts, widths))
    return min(cap, max(28.0, needed * line_pt + 10.0))


def header_style(cell):
    cell.font = Font(name="Calibri", size=10.5, bold=True, color=XL_COCOA)
    cell.fill = PatternFill("solid", fgColor=XL_ORANGE)
    cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
    cell.border = HEADER_BORDER


def body_style(cell, center: bool = False):
    cell.font = Font(name="Calibri", size=10, color=XL_TEXT)
    cell.fill = PatternFill("solid", fgColor=XL_PAPER)
    cell.alignment = Alignment(
        horizontal="center" if center else "left",
        vertical="top",
        wrap_text=True,
    )
    cell.border = CELL_BORDER


# ---------------------------------------------------------------- Sheet 1: 主表
wb = Workbook()
ws = wb.active
ws.title = "en_kp"
ws.sheet_properties.tabColor = XL_ORANGE
wb.properties.title = "en_kp"
wb.properties.subject = "Langly 英语知识点主表（Table-en_kp-知识点）"

for col, spec in enumerate(FIELDS, start=1):
    letter = get_column_letter(col)
    # 表头：只写 SQLite 列名，显示值/含义/规范放批注，保证可直接导入数据库
    cell = ws.cell(row=1, column=col, value=spec["field"])
    header_style(cell)
    tip = Comment(
        "显示值：{}\n含义：{}\n填写规范：{}".format(
            spec["display"], spec["meaning"], spec["spec"]
        ),
        "Langly",
    )
    tip.width, tip.height = 340, 170
    cell.comment = tip
    # 数据：第 2 行起，本版仅第一条知识点
    data = ws.cell(row=2, column=col, value=spec["value"])
    body_style(data, center=spec["field"] in ("id", "point_id", "translation_lang"))
    ws.column_dimensions[letter].width = spec["width"]

ws.row_dimensions[1].height = 30
ws.row_dimensions[2].height = row_height(
    [s["value"] for s in FIELDS], [s["width"] for s in FIELDS]
)
ws.freeze_panes = "C2"  # 冻结表头 + id / point_id 两个标识列
ws.sheet_view.showGridLines = False
ws.sheet_view.zoomScale = 85

# ---------------------------------------------------------------- Sheet 2: 字段说明
ws2 = wb.create_sheet("字段说明")
ws2.sheet_properties.tabColor = XL_COCOA
ws2.sheet_view.showGridLines = False

dict_headers = ["字段", "显示值", "含义", "填写规范 / 约定"]
dict_widths = [22, 32, 30, 72]
for col, name in enumerate(dict_headers, start=1):
    cell = ws2.cell(row=1, column=col, value=name)
    header_style(cell)
    ws2.column_dimensions[get_column_letter(col)].width = dict_widths[col - 1]

for row, spec in enumerate(FIELDS, start=2):
    texts = [spec["field"], spec["display"], spec["meaning"], spec["spec"]]
    for col, text in enumerate(texts, start=1):
        cell = ws2.cell(row=row, column=col, value=text)
        body_style(cell, center=(col == 1))
        if col == 1:
            cell.font = Font(name="Calibri", size=10, bold=True, color=XL_COCOA)
    ws2.row_dimensions[row].height = row_height(texts, dict_widths, line_pt=14.0, cap=140.0)

ws2.row_dimensions[1].height = 28
ws2.freeze_panes = "B2"
ws2.auto_filter.ref = "A1:D{}".format(len(FIELDS) + 1)

# 单元格内英文/中文混排统一字体，避免部分预览器把空白格渲染成黑块
for sheet in (ws, ws2):
    for row in sheet.iter_rows():
        for cell in row:
            if cell.value is None:
                cell.fill = PatternFill("solid", fgColor=XL_WHITE)

wb.active = 0
wb.save(OUTPUT)
print("SAVED", OUTPUT)
