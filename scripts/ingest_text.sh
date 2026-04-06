#!/usr/bin/env bash
#===============================================================================
# LogiMind — ingest-text: 摄入本地文件或管道输入（粘贴内容）
# Usage: logimind ingest-text [file]
#        cat file.md | logimind ingest-text
#
# 用途：微信公众号等需要登录的来源，无法直接抓取时，
#       可复制文章正文，通过管道或文件方式摄入。
#===============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
source "$SKILL_DIR/config.sh"

#-------------------------------------------------------------------------------
# 追加到 All-Sources.md（简化版）
#-------------------------------------------------------------------------------
append_sources() {
    local slug="$1"
    local title="$2"
    local type="$3"
    local clipped_at="$(date +%Y-%m-%d)"

    local index_file="$LOGIMIND_INDEXES/All-Sources.md"
    if [[ ! -f "$index_file" ]]; then
        mkdir -p "$(dirname "$index_file")"
        cat > "$index_file" <<'HEADER'
# 全部来源索引

> 自动维护。每次编译后由 LLM 更新。

| ID | 标题 | 作者 | 类型 | 来源URL | 添加日期 | 编译状态 | PARA |
|----|------|------|------|---------|----------|----------|------|
HEADER
    fi

    local id
    id="$(date +%Y%m%d%H%M%S)"
    echo "| $id | ${title:-${slug}} | | $type | | $clipped_at | raw | |" >> "$index_file"
}

#-------------------------------------------------------------------------------
# 追加操作日志
#-------------------------------------------------------------------------------
append_log() {
    local action="$1"
    local detail="$2"
    local log_file="$LOGIMIND_VAULT/log.md"

    mkdir -p "$(dirname "$log_file")"
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
# 生成 slug
#-------------------------------------------------------------------------------
make_slug() {
    local text="$1"
    # 从首行或前50字生成 slug
    local first_line
    first_line="$(echo "$text" | head -1 | sed 's/^#*//' | sed 's/[[:space:]]*$//' | cut -c1-50)"
    first_line="${first_line:-untitled}"
    echo "$first_line" | sed -E 's/[^a-zA-Z0-9\u4e00-\u9fff]+/-/g' | sed 's/^-//' | sed 's/-$//'
}

#-------------------------------------------------------------------------------
# 提取元信息（从 frontmatter 或首行标题）
#-------------------------------------------------------------------------------
extract_meta() {
    local content="$1"
    local title
    title="$(echo "$content" | grep -m1 '^#' | sed 's/^#*//' | sed 's/^[[:space:]]*//' | cut -c1-200)"
    echo "${title:-untitled}"
}

#-------------------------------------------------------------------------------
# 主逻辑
#-------------------------------------------------------------------------------
main() {
    logimind_ensure_dirs || exit 1

    local content=""
    local title=""
    local type="article"

    if [[ $# -eq 0 ]] || [[ "$1" == "-" ]]; then
        # 管道输入：读取 stdin
        if [[ -t 0 ]]; then
            echo "Usage: logimind ingest-text [file]" >&2
            echo "       cat file.md | logimind ingest-text" >&2
            exit 1
        fi
        content="$(cat)"
    else
        # 文件输入
        if [[ ! -f "$1" ]]; then
            echo "ERROR: File not found: $1" >&2
            exit 1
        fi
        content="$(cat "$1")"
    fi

    if [[ -z "$content" ]]; then
        echo "ERROR: No content provided" >&2
        exit 1
    fi

    # 提取标题
    title="$(extract_meta "$content")"
    local slug
    slug="$(make_slug "$title")"

    # 生成文件名
    local date_str
    date_str="$(date +%Y-%m-%d)"
    local filename="${date_str}-${slug}"
    local dest_file="$LOGIMIND_ARTICLES/${filename}.md"

    # 如果文件已存在，加时间戳
    if [[ -f "$dest_file" ]]; then
        filename="${date_str}-${slug}-$(date +%H%M%S)"
        dest_file="$LOGIMIND_ARTICLES/${filename}.md"
    fi

    # 写入（含 frontmatter）
    {
        echo '---'
        echo "source_type: text-input"
        echo "author: \"\""
        echo "published: \"\""
        echo "clipped_at: \"$date_str\""
        echo "tags: []"
        echo "type: $type"
        echo "status: raw"
        echo "note: \"微信公众号等需要登录的内容，通过粘贴方式摄入。\""
        echo '---'
        echo ""
        echo '> 原始资料，不做修改。编译产物见 wiki/summaries/ 对应文件。'
        echo ""
        echo "$content"
    } > "$dest_file"

    # 更新索引和日志
    append_sources "$filename" "$title" "$type"
    append_log "ingest-text" "管道/文件输入 → $dest_file (title: $title)"

    echo "✓ Saved to $dest_file"
    echo ""
    echo "Next: Run 'logimind compile $dest_file' to process this content"
}

main "$@"
