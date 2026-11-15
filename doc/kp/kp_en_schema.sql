-- Langly · kp_en（英语知识点主表）DDL
-- 数据来源：doc/kp/en_kp.json（JSON 为权威源，本库由 .en_kp.ref/build_db.py 生成 / 同步）
-- 约定：数组类字段统一存「JSON 数组字符串」(TEXT)，读取端用 jsonDecode 还原；
--       多行文本（translation_content / explanation / key_point）保留 \n 原样存 TEXT。
-- 表名与字段顺序与 en_kp.json 的 12 个键一一对应，便于逐字段核对。

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS kp_en (
  id                  INTEGER PRIMARY KEY,
  point_id            TEXT    NOT NULL UNIQUE,          -- 业务编号，如 KP-001
  point_content       TEXT    NOT NULL,                 -- 知识点原文
  tag                 TEXT    NOT NULL DEFAULT '[]',    -- JSON 数组字符串
  translation_lang    TEXT    NOT NULL,                 -- BCP-47，如 zh-CN
  translation_content TEXT    NOT NULL DEFAULT '',
  examples            TEXT    NOT NULL DEFAULT '[]',    -- JSON 数组字符串
  explanation         TEXT    NOT NULL DEFAULT '',
  synonym_points      TEXT    NOT NULL DEFAULT '[]',    -- JSON 数组字符串
  antonym_points      TEXT    NOT NULL DEFAULT '[]',    -- JSON 数组字符串
  extended_points     TEXT    NOT NULL DEFAULT '[]',    -- JSON 数组字符串
  key_point           TEXT    NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_kp_en_content ON kp_en(point_content);
