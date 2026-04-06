#!/usr/bin/env bash
#===============================================================================
# LogiMind — compile: 三步编译 raw/ → wiki/summaries/ + PARA 分类
# Usage: logimind compile [file]
#         如果指定 file，只编译该文件；否则扫描所有未编译素材
#===============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
source "$SKILL_DIR/config.sh"

#-------------------------------------------------------------------------------
# 查找未编译的 raw 文件
#-------------------------------------------------------------------------------
logimind_find_uncompiled() {
    local raw_dir="$1"
    local summaries_dir="$2"

    find "$raw_dir" -type f -name "*.md" | sort | while read -r raw_file; do
        local rel_path
        rel_path="$(realpath --relative-to="$raw_dir" "$raw_file")"
        rel_path="${rel_path%.md}"

        local summary_file="${summaries_dir}/${rel_path}.md"
        if [[ ! -f "$summary_file" ]]; then
            echo "$raw_file|$rel_path"
        fi
    done
}

#-------------------------------------------------------------------------------
# 追加操作日志
#-------------------------------------------------------------------------------
logimind_append_log() {
    local action="$1"
    local detail="$2"
    local log_file="$LOGIMIND_VAULT/log.md"

    if [[ ! -f "$log_file" ]]; then
        cat > "$log_file" <<'HEADER'
# LogiMind 操作日志

> append-only 操作记录

---
HEADER
    fi
    echo "" >> "$log_file"
    echo "## [$(date +%Y-%m-%d\ %H:%M)] $action" >> "$log_file"
    echo "- $detail" >> "$log_file"
}

#-------------------------------------------------------------------------------
# 打印编译指南（供 Agent 参照执行）
#-------------------------------------------------------------------------------
print_compile_guide() {
    local raw_file="$1"
    local rel_path="$2"

    local base_name
    base_name="$(basename "$raw_file")"

    # 从 frontmatter 读取 type
    local content_type
    content_type=$(sed -n '/^type:/p' "$raw_file" 2>/dev/null | head -1 | sed 's/type: *//' | tr -d ' ')
    content_type="${content_type:-article}"

    echo "============================================"
    echo "  LogiMind Compile: $base_name"
    echo "============================================"
    echo ""
    echo "Input:  $raw_file"
    echo "Output: $LOGIMIND_SUMMARIES/${rel_path}.md"
    echo "Type:   $content_type"
    echo ""
    echo "---"
    echo "三步编译流程:"
    echo ""
    echo "  1. 【强制】交叉链接（先做！）"
    echo "     在 wiki/ 目录搜索相关内容："
    echo "     grep -r '关键词' $LOGIMIND_WIKI/"
    echo "     找到相关页面后，在摘要中添加 [[wiki/xxx]] 链接"
    echo "     必须写入 wiki 条目之前完成！"
    echo ""
    echo "  2. 【第一步】浓缩"
    echo "     - 核心结论不超过 3 条"
    echo "     - 关键证据"
    echo "     - 术语表"
    echo ""
    echo "  3. 【第二步】质疑（芒格反驳法）"
    echo "     - 逻辑链检查"
    echo "     - 前提假设清单"
    echo "     - 不适用场景 + 反例"
    echo ""
    echo "  4. 【第三步】对标（它山之石）"
    echo "     - 跨域映射"
    echo "     - 可迁移洞察"
    echo "     - 新连接"
    echo ""
    echo "  5. 【PARA 分类】"
    echo "     根据内容判断 PARA 类型："
    echo "     - 有目标+截止日期 → projects/"
    echo "     - 持续责任领域   → areas/"
    echo "     - 感兴趣暂无行动 → resources/ (默认)"
    echo "     - 已完成/已放弃   → archives/"
    echo ""
    echo "  6. 【概念提取】"
    echo "     从编译结果提取概念："
    echo "     - 新概念 → 创建 wiki/concepts/{概念名}.md"
    echo "     - 老概念 → 追加证据到现有文件"
    echo ""
    echo "  7. 【更新索引】"
    echo "     - 更新 wiki/indexes/All-Concepts.md"
    echo "     - 更新 wiki/indexes/All-Sources.md (编译状态改为 compiled)"
    echo "     - 追加 log.md"
    echo ""
    echo "---"
    echo "模板文件: $SKILL_DIR/scripts/tpl/summary-template.md"
    echo "============================================"
}

#-------------------------------------------------------------------------------
# 主逻辑
#-------------------------------------------------------------------------------
main() {
    # 前置检查
    logimind_ensure_dirs || exit 1

    local target_file=""
    if [[ $# -gt 0 ]]; then
        target_file="$1"
    fi

    local count=0

    if [[ -n "$target_file" ]]; then
        # 指定文件编译
        if [[ -f "$target_file" ]]; then
            local raw_dir="$LOGIMIND_RAW"
            local rel_path="${target_file#$raw_dir/}"
            rel_path="${rel_path%.md}"

            local summary_file="$LOGIMIND_SUMMARIES/${rel_path}.md"
            if [[ -f "$summary_file" ]]; then
                echo "Already compiled: $summary_file"
                exit 0
            fi

            print_compile_guide "$target_file" "$rel_path"
            count=1
        else
            echo "ERROR: File not found: $target_file" >&2
            exit 1
        fi
    else
        # 扫描所有未编译文件
        echo "Scanning for uncompiled files..."
        echo ""

        local found=0
        while IFS='|' read -r raw_file rel_path; do
            [[ -z "$raw_file" ]] && continue
            found=1
            print_compile_guide "$raw_file" "$rel_path"
            echo ""
            count=$((count + 1))
        done < <(logimind_find_uncompiled "$LOGIMIND_RAW" "$LOGIMIND_SUMMARIES")

        if [[ $found -eq 0 ]]; then
            echo "No uncompiled files found."
            exit 0
        fi
    fi

    echo ""
    echo "Total: $count file(s) to compile"
    echo ""
    echo "IMPORTANT: Execute the 3-step compilation manually or via Agent,"
    echo "          using the templates from CLAUDE.md and scripts/tpl/"
    echo ""
    echo "After compilation:"
    echo "  1. Update All-Sources.md (set compiled status)"
    echo "  2. Update All-Concepts.md"
    echo "  3. Append to log.md"

    if [[ $count -gt 0 ]]; then
        logimind_append_log "compile scan" "Found $count uncompiled file(s)"
    fi
}

main "$@"
