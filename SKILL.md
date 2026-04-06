---
name: logimind
description: LogiMind — LLM Wiki 知识管理系统，OpenClaw/Claude Code 上的第二大脑。基于 Karpathy LLM Wiki 2.0 + PARA 分类 + 三步编译法。服务人类在 Obsidian 里浏览知识库。核心能力：(1) ingest 抓取链接到 raw/ 支持多平台（Twitter/YouTube/B站/微信公众号/小红书/通用网页）；(2) compile 三步编译（浓缩/质疑/对标）到 wiki/summaries/ + PARA 分类（projects/areas/resources/archives）；(3) lint 健康检查（一致性/完整性/孤岛检测，支持 --fix 自动修复）；(4) query 知识问答。强制原则：Raw First（先保存原始文件）、交叉链接前置（写入 wiki 前必须先 grep 找到相关页面并添加链接）、PARA 分类必做。当用户提到以下场景时触发：发送 URL 或"抓取这个链接"、"编译"、"处理新内容"、"健康检查"、"检查知识库"、"对知识库提问"、提到"第二大脑"、"LLM Wiki"、Karpathy、LogiMind、三步编译、PARA、或任何知识管理相关操作。即使用户没有明确说"logimind"命令，只要涉及个人知识管理、知识库构建、内容摄取，都应该考虑使用此 skill。
---

# LogiMind — Skill Definition

LogiMind 是基于 Karpathy LLM Wiki 2.0 的知识管理系统：
- **raw/** — 原始资料，只读不修改
- **wiki/** — LLM 编译产物 + PARA 分类
- **CLAUDE.md** — 操作规范（Schema）

## 架构概览

```
logimind skill ( ~/.agents/skills/logimind/ )
├── SKILL.md          ← 本文件，skill 定义
├── CLAUDE.md         ← Agent 操作规范 + 模板
├── README.md         ← 人类可读使用说明
├── config.sh         ← vault 路径 + PARA 目录配置
└── scripts/
    ├── logimind.sh   ← 主入口 CLI
    ├── fetch_content.sh ← 多平台抓取（Twitter/YouTube/B站/微信等）
    ├── jina.sh       ← Jina Reader 封装（简单场景用）
    ├── ingest.sh     ← URL → raw/ + 自动类型检测
    ├── compile.sh    ← 三步编译 + PARA 分类 + 强制交叉链接
    ├── lint.sh       ← 健康检查（doctor.sh 风格，支持 --fix）
    ├── query.sh      ← 知识问答
    └── tpl/          ← 模板文件
```

## 四个核心命令

| 命令 | 触发场景 | 输出 |
|------|---------|------|
| `logimind ingest <URL> [type]` | 用户发 URL、"抓取" | `raw/{type}/YYYY-MM-{slug}.md` |
| `logimind compile [file]` | "编译"、"处理新内容" | `wiki/summaries/` + `wiki/{para}/` |
| `logimind lint [--fix] [quick\|full]` | "健康检查"、"检查知识库" | `outputs/health/YYYY-MM-DD-health.md` |
| `logimind query <问题>` | 对知识库的复杂提问 | `outputs/qa/YYYY-MM-DD-{slug}.md` |

## PARA 分类（核心！）

所有编译产出必须按 PARA 分类写入对应目录：

| PARA | 判断标准 |
|------|---------|
| **projects** | 有目标 + 截止日期 |
| **areas** | 持续责任领域 |
| **resources** | 感兴趣暂无行动（默认） |
| **archives** | 已完成 / >3 个月无行动 |

## 三步编译法

1. **强制**：交叉链接前置 — 写入 wiki 前先 grep wiki/ 找到相关页面
2. **第一步：浓缩** — 核心结论≤3条 + 关键证据 + 术语表
3. **第二步：质疑** — 芒格反驳法：前提假设 + 不适用场景 + 反例
4. **第三步：对标** — 跨域映射 + 可迁移洞察 + 新连接

## 多平台抓取

| 平台 | 工具 |
|------|------|
| Twitter/X | Jina Reader |
| YouTube/B站 | yt-dlp 字幕 |
| 微信公众号/小红书 | agent-reach 或 Jina Reader |
| 普通网页 | Jina Reader |

## 关键原则

1. **Raw First**：先保存原始文件到 `raw/`，再处理。顺序不能反。
2. **强制交叉链接**：写入任何 wiki 条目之前，必须先搜索相关页面并添加 `[[wiki/xxx]]` 链接。
3. **PARA 必做**：每次 compile 必须判断 PARA 分类。
4. **与 MEMORY.md 分离**：LogiMind 服务人类知识库，不写 MEMORY.md。
5. **降级策略**：Obsidian CLI 失败时降级到纯 fs 操作。

## 详细文档

- **Agent 操作规范**：`~/.agents/skills/logimind/CLAUDE.md`
- **使用说明**：`~/.agents/skills/logimind/README.md`
- **Vault 路径**：`~/documents/second-brain/`
