#!/usr/bin/env bash
#===============================================================================
# LogiMind — query: 知识问答
# Usage: logimind query <问题>
# 输出: outputs/qa/YYYY-MM-DD-{slug}.md
#===============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
source "$SKILL_DIR/config.sh"

#-------------------------------------------------------------------------------
# 生成 slug
#-------------------------------------------------------------------------------
logimind_slug() {
    echo "$1" | sed -E 's/[^a-zA-Z0-9]+/-/g' | cut -c1-60 | tr '[:upper:]' '[:lower:]'
}

#-------------------------------------------------------------------------------
# 主逻辑
# 注意：实际问答由 Agent/LLM 执行
#-------------------------------------------------------------------------------
main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: logimind query <问题>" >&2
        exit 1
    fi

    local question="$*"

    # 前置检查
    logimind_ensure_dirs || exit 1

    local date_str
    date_str="$(date +%Y-%m-%d)"
    local slug
    slug="$(logimind_slug "$question")"
    local qa_file="$LOGIMIND_QA/${date_str}-${slug}.md"

    echo "Question: $question"
    echo "Output: $qa_file"
    echo ""
    echo "NOTE: Run 'Agent' with CLAUDE.md loaded to answer this question"
    echo "      using wiki/summaries/ and wiki/concepts/ as knowledge base."
    echo ""
    echo "Answer format should include:"
    echo "  - TL;DR (one sentence)"
    echo "  - 结论 (detailed answer)"
    echo "  - 证据 (with links to sources)"
    echo "  - 不确定性"
    echo "  - 关联"

    # 生成占位模板
    {
        echo '---'
        echo "question: \"$question\""
        echo "asked_at: \"$date_str\""
        echo "sources: []"
        echo '---'
        echo ""
        echo "# $question"
        echo ""
        echo "## TL;DR"
        echo "[（由 Agent/LLM 填写：一句话回答）]"
        echo ""
        echo "## 结论"
        echo "[（由 Agent/LLM 填写）]"
        echo ""
        echo "## 证据"
        echo "- [链接回原始来源]"
        echo ""
        echo "## 不确定性"
        echo "[哪些地方还不确定]"
        echo ""
        echo "## 关联"
        echo "- 相关概念：[[链接]]"
        echo "- 相关Q&A：[[链接]]"
    } > "$qa_file"

    echo "✓ Template saved: $qa_file"
}

main "$@"
