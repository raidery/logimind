# LogiMind — 使用说明

> LogiMind = OpenClaw/Claude Code 上的第二大脑，基于 Karpathy LLM Wiki 2.0 + PARA 分类。

---

## 快速开始

### 安装

**方式一：一键安装（推荐）**

在 OpenClaw 或 Claude Code 中直接说：

```
请帮我从 https://github.com/raidery/logimind 安装第二大脑技能
```

**方式二：手动安装**

```bash
# 克隆到 skills 目录
git clone git@github.com:raidery/logimind.git ~/.agents/skills/logimind

# 注入到 MEMORY.md（让 AI 知道 LogiMind 在哪）
~/.agents/skills/logimind/install.sh --inject-only

# 初始化 vault（如果还没有）
mkdir -p ~/documents/second-brain/{raw/{articles,podcasts,tweets,voice,images,files,chats},wiki/{summaries,concepts,indexes,projects,areas,resources,archives},outputs/{qa,health}}

# 在 Obsidian 中打开 ~/documents/second-brain/ vault
```

Vault 位于 `~/documents/second-brain/`，Obsidian 直接打开即可浏览。

### 四个核心命令

#### 抓取链接
```
@logimind ingest https://example.com/article
@logimind ingest https://twitter.com/user/status/123 tweet
```
支持多平台自动检测：Twitter/X → Jina Reader、YouTube/B站 → yt-dlp、微信公众号/小红书 → agent-reach。

#### 编译新内容
```
@logimind compile
```
对 `raw/` 中所有未编译的素材执行三步编译，输出到 `wiki/summaries/`，并按 PARA 分类写入对应目录。

#### 健康检查
```
@logimind lint           # 快速检查
@logimind lint --fix      # 自动修复
@logimind lint full       # 完整检查
```
检查知识库的一致性、完整性、孤岛页面，生成报告到 `outputs/health/`。

#### 知识问答
```
@logimind query 为什么 LLM Wiki 比 RAG 更好？
```
对知识库进行复杂问答，答案沉淀到 `outputs/qa/`。

---

## 三步编译法

每篇内容都会经过三次深度处理：

**第一步：浓缩** — 用剃刀法则提取核心结论，不超过 3 条。

**第二步：质疑** — 用芒格反驳法找出前提假设和不适用场景。

**第三步：对标** — 跨域类比，找到可迁移的洞察。

---

## PARA 分类

所有内容必须归入 PARA 之一：

| 类型 | 说明 |
|------|------|
| **projects** | 有明确目标 + 截止日期 |
| **areas** | 持续维护的责任领域 |
| **resources** | 感兴趣但暂无行动（默认） |
| **archives** | 已完成或长期无行动 |

---

## 目录结构

| 目录 | 用途 |
|------|------|
| `raw/` | 原始资料，只读不修改 |
| `wiki/summaries/` | 每篇内容的三步编译摘要 |
| `wiki/concepts/` | 提取的概念条目 |
| `wiki/projects/` | PARA: 有目标+截止日期 |
| `wiki/areas/` | PARA: 持续责任 |
| `wiki/resources/` | PARA: 感兴趣暂无行动 |
| `wiki/archives/` | PARA: 已完成/放弃 |
| `wiki/indexes/` | 自动维护的索引 |
| `outputs/qa/` | 知识问答沉淀 |
| `outputs/health/` | 健康检查报告 |

---

## 与 MEMORY.md 的分工

| 系统 | 服务对象 | 内容 |
|------|---------|------|
| **MEMORY.md** | OpenClaw Agent 自身 | Agent 的记忆、决策依据 |
| **LogiMind** | 人类 | 知识库，在 Obsidian 里浏览 |

---

## 在 Obsidian 中使用

1. 用 Obsidian 打开 `~/documents/second-brain/` vault
2. 启用图谱视图（Graph View）可视化知识网络
3. 使用 Dataview 插件查询 frontmatter 动态表格
4. 安装 qmd 可获得本地 md 搜索引擎

---

## 健康检查频率

建议每周运行一次 `logimind lint full`，由 OpenClaw Cron 定时触发。

---

## 依赖工具

### 必需工具
| 工具 | 用途 |
|------|------|
| curl | 网络请求 |
| git | 版本管理 |

### Optional Tools
Install these for full functionality:

| Tool | Function | Install |
|------|----------|---------|
| Whisper | Speech-to-text | `pip3 install whisper` |
| exiftool | Image metadata | `brew install exiftool` |
| yt-dlp | YouTube/Bilibili subtitles | `brew install yt-dlp` |
| agent-reach | Twitter/Xiaohongshu/WeChat | see below |

agent-reach install:

Please install agent-reach: https://raw.githubusercontent.com/Panniantong/agent-reach/main/docs/install.md
