#!/bin/bash
# install.sh — LogiMind 安装脚本
# 用法: ./install.sh [--inject-only]

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 如果是 --inject-only，直接运行注入然后退出
if [ "$1" = "--inject-only" ]; then
    inject_to_openclaw() {
        OPENCLAW_MEMORY=""
        for path in \
            "$HOME/.openclaw/workspace/MEMORY.md" \
            "$HOME/.claude/projects/MEMORY.md" \
            "$HOME/MEMORY.md"
        do
            if [ -f "$path" ]; then
                OPENCLAW_MEMORY="$path"
                break
            fi
        done

        if [ -z "$OPENCLAW_MEMORY" ]; then
            echo "未找到 OpenClaw MEMORY.md，跳过"
            return 0
        fi

        INJECT_CONTENT="
---

## 🧠 LogiMind — 第二大脑技能

**Skill 路径：** \`$PROJECT_DIR/\`

当需要知识积累、内容收藏时，使用 LogiMind 第二大脑系统。

**重要：** 处理前先读取 \`\$PROJECT_DIR/CLAUDE.md\`（定义完整处理流程）

**使用场景：**
- 文章/链接摄入 → \`@logimind ingest <url>\`
- 内容编译 → \`@logimind compile\`
- 健康检查 → \`@logimind lint\`
- 知识问答 → \`@logimind query <问题>\`

**用法：** 直接把内容或链接发给 AI，说"存入第二大脑"或"@logimind ingest <链接>"。

"

        if grep -q "LogiMind.*第二大脑技能" "$OPENCLAW_MEMORY" 2>/dev/null; then
            echo "发现已有 LogiMind 注入，更新..."
            sed -i.bak '/^## 🧠 LogiMind/,/^---$/d' "$OPENCLAW_MEMORY"
            echo "$INJECT_CONTENT" >> "$OPENCLAW_MEMORY"
            echo "已更新注入内容"
        else
            echo "$INJECT_CONTENT" >> "$OPENCLAW_MEMORY"
            echo "已注入到 $OPENCLAW_MEMORY"
        fi
    }
    inject_to_openclaw
    exit 0
fi

echo "LogiMind 安装脚本"
echo ""
echo "安装路径: $PROJECT_DIR"
echo ""
echo "用法:"
echo "  ./install.sh --inject-only   # 仅注入到 MEMORY.md"
echo ""
echo "或者手动在 OpenClaw/Claude Code 中说:"
echo "  请帮我从 https://github.com/raidery/logimind 安装第二大脑技能"
