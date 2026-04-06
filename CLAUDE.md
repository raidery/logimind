---
name: logimind-claude
description: LogiMind Agent 操作规范 — 三步编译法 + PARA 分类 + 强制交叉链接
---

# LogiMind — Agent 操作规范

> LogiMind = OpenClaw/Claude Code 上的第二大脑，服务人类在 Obsidian 里浏览知识库。
> Vault 路径：`~/documents/second-brain/`
> Skill 路径：`~/.agents/skills/logimind/`

---

## 一、目录结构

```
~/documents/second-brain/     ← Vault 根目录
├── CLAUDE.md                  ← LogiMind 操作规范（本文档）
├── log.md                   ← 操作日志（append-only）
│
├── raw/                      ← 原始资料，只读不修改
│   ├── articles/            # 网页/博客/新闻
│   ├── podcasts/            # 播客/视频字幕
│   ├── tweets/              # 推文/短内容
│   ├── voice/               # 语音录音
│   ├── images/              # 图片/截图
│   ├── files/               # PDF/文档
│   └── chats/               # 聊天记录
│
├── wiki/                     ← LLM 编译产物
│   ├── summaries/           # 每篇内容的三步编译摘要
│   ├── concepts/            # 概念条目
│   ├── indexes/             # 自动维护索引
│   │   ├── All-Sources.md
│   │   └── All-Concepts.md
│   ├── projects/            # PARA: 有目标+截止日期
│   ├── areas/               # PARA: 持续责任
│   ├── resources/           # PARA: 感兴趣暂无行动
│   └── archives/            # PARA: 已完成/放弃
│
└── outputs/
    ├── qa/                  # 知识问答沉淀
    └── health/              # 健康检查报告
```

---

## 二、七种内容类型

| 类型 | raw 目录 | 处理工具 |
|------|---------|---------|
| article | raw/articles/ | fetch_content.sh → Jina Reader |
| podcast | raw/podcasts/ | fetch_content.sh → yt-dlp |
| tweet | raw/tweets/ | Jina Reader |
| voice | raw/voice/ | voice_to_text.sh |
| image | raw/images/ | extract_exif.sh |
| file | raw/files/ | extract_pdf_text.sh |
| chat | raw/chats/ | 直接处理 |

---

## 三、核心原则

### 原则 1：Raw First
**先保存原始文件到 `raw/`，再处理。顺序不能反。**

```
收到内容 → 判断类型 → 保存 raw → 执行处理 → PARA 分类 → 写入 wiki
```

### 原则 2：强制交叉链接（写入前必做！）
**在写入任何 wiki 条目之前，必须先搜索 wiki/ 目录找到相关页面并添加链接。**

```
写入 wiki 条目之前：
  1. grep -r "关键词" wiki/concepts/ wiki/summaries/ wiki/projects/ wiki/areas/ wiki/resources/
  2. 找到相关页面后，添加到 [[wiki/xxx]] 格式
  3. 完成后才写入目标 wiki 文件
```

这条是**强制步骤**，不可跳过。

### 原则 3：PARA 分类
所有 wiki 条目必须归入 PARA 之一：

| PARA | 判断标准 | 示例 |
|------|---------|------|
| **projects** | 有明确目标 + 截止日期 + 行动 | "3个月内学会 Python" |
| **areas** | 持续维护的责任领域 | 健康、财务、人际关系 |
| **resources** | 感兴趣但暂无行动 | 某个技术方向、收藏的文章 |
| **archives** | 已完成或 >3 个月无行动 | 旧项目、已读内容 |

### 原则 4：与 MEMORY.md 分离
- **MEMORY.md** = Agent 自身记忆，服务决策
- **LogiMind** = 人类知识库，在 Obsidian 里浏览
- Agent 不主动写 LogiMind，除非人类明确要求

---

## 四、三步编译法（每篇内容必做）

### 第一步：浓缩（第一性原理 + 剃刀法则）

> 基于认知负荷理论：人类工作记忆最多同时处理 2-4 个信息块。

**规则**：
- 先抓主线，再深度质疑（顺序不能反）
- 用剃刀法则删减：删掉它会影响理解吗？不会就删
- **输出**：核心结论（不超过3条）+ 关键证据 + 核心术语表

```
## 第一步：浓缩（第一性原理 + 剃刀法则）

### 核心结论（不超过3条）
1.
2.
3.

### 关键证据
-

### 核心术语
| 术语 | 定义 |
|------|------|
```

### 第二步：质疑（芒格反驳法）

> "如果我不能比别人更好地反驳自己的观点，我就不配拥有这个观点。"

**规则**：
- 逻辑链检查：推理链在哪里断了？
- 前提假设：结论依赖哪些前提？每个隐含前提 + "如果该前提不成立会怎样"
- 不适用场景：这个观点在什么情况下不成立？写出具体反例
- **输出**：前提假设清单 + 不适用场景 + 反例

```
## 第二步：质疑（芒格反驳法）

### 逻辑链检查
- 逻辑链完整 / 在哪里断了：

### 前提假设清单
| # | 隐含前提 | 如果不成立会怎样 |
|---|----------|-----------------|
| 1 | | |

### 不适用场景
- 这个观点在什么情况下不适用：
- 反例：
```

### 第三步：对标（它山之石可以攻玉）

**规则**：
- 跨域类比：其他领域有类似现象吗？建立映射表
- 迁移应用：这些知识还能用在哪儿？
- 它山之石：其他领域的方法论能否迁移到当前领域？
- **输出**：跨域映射表 + 可迁移洞察 + 新连接

```
## 第三步：对标（它山之石可以攻玉）

### 跨域映射
| 当前领域概念 | 类比领域 | 类比对象 | 启示 |
|--------------|----------|----------|------|

### 可迁移洞察
-

### 新连接
- 可以和 [[概念名]] 关联
- 可以用于 [场景]
```

---

## 五、四个核心命令的工作流

### ingest — 抓取链接

```
1. 判断内容类型（article/podcast/tweet）
2. fetch_content.sh 抓取 → 转 markdown
   · Twitter/X → Jina Reader
   · YouTube/B站 → yt-dlp 字幕
   · 微信公众号/小红书 → agent-reach 或 Jina Reader
   · 普通网页 → Jina Reader
3. 添加 YAML frontmatter
   · source_url / author / published / clipped_at / tags / type / status: raw
4. 存入 raw/{type}/YYYY-MM-{slug}.md
5. 追加到 wiki/indexes/All-Sources.md
6. 追加 log.md 记录
```

### compile — 三步编译

```
1. 扫描 raw/，找出未编译的素材（没有对应的 wiki/summaries/ 文件）
2. 【强制】交叉链接：grep wiki/ 找到相关页面，写入前先添加 [[wiki/xxx]] 链接
3. 读取 raw/ 素材内容
4. LLM 按三步编译法处理，输出到 wiki/summaries/
5. 判断 PARA 分类，根据分类写入对应目录：
   · projects/ → 有目标+截止日期
   · areas/ → 持续责任
   · resources/ → 感兴趣暂无行动（默认）
   · archives/ → 已完成/已放弃
6. 从编译结果中提取概念
   · 新概念 → 创建 wiki/concepts/{概念名}.md
   · 老概念 → 追加证据和来源到现有文件
7. 更新 wiki/indexes/All-Concepts.md
8. 更新 wiki/indexes/All-Sources.md（编译状态改为 compiled）
9. 追加 log.md
```

### lint — 健康检查

```
1. 一致性检查
   · 扫描 wiki/concepts/ 中是否有定义冲突
   · 同一概念不同页面描述矛盾
2. 完整性检查
   · 哪些概念条目缺：定义/证据/质疑/跨域连接
   · 哪些摘要缺：核心结论/关键证据
3. 孤岛检测
   · 入链 < 2 且 出链 < 2 的页面
   · 建议应该连接到哪些概念/摘要
4. 生成报告 → outputs/health/YYYY-MM-DD-health.md
5. 报告给用户，列出待修复项
```

### query — 知识问答

```
1. 扫描 wiki/（先用 index，再用全文搜索）
2. 找到相关 summaries + concepts
3. 【强制】交叉链接：搜索相关概念，确保回答引用了 wiki 内容
4. LLM 综合答案，带来源引用
5. 写入 outputs/qa/YYYY-MM-DD-{slug}.md
6. 如果答案有价值 → 追加到相关 concept 或形成新 concept
```

---

## 六、PARA 分类决策表

### 判断流程

```
内容是否有明确目标？
  是 → 是否有截止日期？
    是 → projects/
    否 → projects/ 或 areas/（取决于是否有明确终点）
  否 → 是否是持续责任领域？
    是 → areas/
    否 → 是否已 >3 个月无行动？
      是 → archives/
      否 → resources/
```

### 示例

| 内容 | PARA |
|------|------|
| "6月前完成 app 开发" | projects |
| "持续维护财务记录" | areas |
| "学习 AI Agent 方向" | resources |
| "已完成的项目笔记" | archives |

---

## 七、文件模板

### 7.1 wiki/summaries/{date}-{slug}.md

```markdown
---
source: "[[raw/articles/YYYY-MM-文件名]]"
compiled_at: "{{date}}"
concepts: []
para: resources
status: compiled
---

# {{标题}} — 三步编译摘要

## 元信息
- **来源**：
- **作者**：
- **类型**：文章 / 播客 / 论文 / 推文
- **原文链接**：
- **编译日期**：
- **PARA**：projects / areas / resources / archives

---

## 第一步：浓缩（第一性原理 + 剃刀法则）

### 核心结论（不超过3条）
1.
2.
3.

### 关键证据
-

### 核心术语
| 术语 | 定义 |
|------|------|

---

## 第二步：质疑（芒格反驳法）

### 逻辑链检查
- 逻辑链完整 / 在哪里断了：

### 前提假设清单
| # | 隐含前提 | 如果不成立会怎样 |
|---|----------|-----------------|
| 1 | | |

### 不适用场景
- 这个观点在什么情况下不适用：
- 反例：

---

## 第三步：对标（它山之石可以攻玉）

### 跨域映射
| 当前领域概念 | 类比领域 | 类比对象 | 启示 |
|--------------|----------|----------|------|

### 可迁移洞察
-

### 新连接
- 可以和 [[wiki/concepts/概念名]] 关联
- 可以用于 [场景]

---

## 关联内容
- [[wiki/concepts/相关概念]] — 关联原因
- [[wiki/summaries/相关摘要]] — 关联原因

---

## 编译产物
- **提取概念**：[列出将在 wiki/concepts/ 中建立或更新的概念]
- **PARA 判断**：[projects/areas/resources/archives] + 判断理由
- **选题启发**：[这条内容可以衍生出什么选题？]
```

### 7.2 wiki/concepts/{概念名}.md

```markdown
---
aliases: []
created_at: "{{date}}"
updated_at: "{{date}}"
sources: []
related_concepts: []
---

# {{概念名}}

## 定义
[一句话定义]

## 第一性原理
[去掉所有装饰后最基本的原理是什么？]

## 证据链
| # | 证据 | 来源 | 强度 |
|---|------|------|------|
| 1 | | | 强/中/弱 |

## 质疑（这个概念在什么情况下不成立？）
- 不适用场景：
- 依赖的前提：
- 反例：

## 跨域连接
- **类比**：
- **迁移**：
- **它山之石**：

## 适用场景
- 场景1：
- 场景2：

## 典型表达
- "引述1"
- "引述2"

## 反向链接
- 被以下摘要引用：[[wiki/summaries/xxx]]
```

### 7.3 wiki/indexes/All-Sources.md

```markdown
# 全部来源索引

> 自动维护。每次编译后由 LLM 更新。

| ID | 标题 | 作者 | 类型 | 来源URL | 添加日期 | 编译状态 | PARA |
|----|------|------|------|---------|----------|----------|------|
```

### 7.4 wiki/indexes/All-Concepts.md

```markdown
# 全部概念索引

> 自动维护。每次编译后由 LLM 更新。

| 概念 | 定义（一句话） | 首次来源 | 相关概念 | 最后更新 |
|------|--------------|----------|----------|----------|
```

### 7.5 outputs/qa/{date}-{slug}.md

```markdown
---
question: ""
asked_at: "{{date}}"
sources: []
---

# {{问题}}

## TL;DR
[一句话回答]

## 结论
[详细回答]

## 证据
- [[wiki/summaries/xxx]] — 说明
- [[wiki/concepts/yyy]] — 说明

## 不确定性
[哪些地方还不确定]

## 关联
- 相关概念：[[wiki/concepts/xxx]]
- 相关Q&A：[[wiki/summaries/yyy]]
```

### 7.6 outputs/health/{date}-health.md

```markdown
---
check_date: "{{date}}"
check_type: weekly
---

# 健康检查报告 — {{date}}

## 概览
| 检查项 | 状态 | 问题数 |
|--------|------|--------|
| 一致性 | ✅/⚠️/❌ | |
| 完整性 | ✅/⚠️/❌ | |
| 孤岛检测 | ✅/⚠️/❌ | |

## 一致性检查
| 问题 | 位置 | 建议 |
|------|------|------|

## 完整性检查
| 概念 | 缺失项 | 建议 |
|------|--------|------|

## 孤岛检测
| 文件 | 入链 | 出链 | 建议连接 |
|------|------|------|----------|

## 本期修复计划
- [ ]
```

---

## 八、交叉链接指南

### 何时做交叉链接

**强制时机**：
- 写入任何 wiki 条目之前（必须先搜索相关页面）
- compile 完成后（从 summary 链接到 concepts）
- query 回答完成后（引用相关 wiki 内容）

**如何做**：
```bash
# 搜索关键词相关页面
grep -r "关键词" wiki/concepts/ wiki/summaries/ wiki/projects/ wiki/areas/ wiki/resources/

# 添加链接格式
[[wiki/summaries/文件名]] — 简要关联原因
[[wiki/concepts/概念名]] — 简要关联原因
```

### 链接放置位置

- **摘要页**：放在"关联内容" section，放在"编译产物"之后
- **概念页**：放在"反向链接" section
- **PARA 页面**：放在"关联内容" section
