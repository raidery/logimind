#!/usr/bin/env bash
#===============================================================================
# LogiMind — ingest: 抓取链接到 raw/
# Usage: logimind ingest <URL> [type]
#         type 可选: article | podcast | tweet | voice | image | file | chat | task
#         不指定则自动检测
#===============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
source "$SKILL_DIR/config.sh"

#-------------------------------------------------------------------------------
# 生成 slug
#-------------------------------------------------------------------------------
logimind_slug() {
    local url="$1"
    echo "$url" | sed -E 's|https?://||' | sed -E 's/[^a-zA-Z0-9]+/-/g' | cut -c1-80
}

#-------------------------------------------------------------------------------
# 检测内容类型
#-------------------------------------------------------------------------------
logimind_detect_type() {
    local url="$1"
    local lower_url
    lower_url="$(echo "$url" | tr '[:upper:]' '[:lower:]')"

    if echo "$lower_url" | grep -qE '(youtube\.com|bilibili\.com|b23\.tv|spotify\.com|podcast)'; then
        echo "podcast"
    elif echo "$lower_url" | grep -qE '(twitter\.com|x\.com)'; then
        echo "tweet"
    else
        echo "article"
    fi
}

#-------------------------------------------------------------------------------
# 确定 raw 子目录
#-------------------------------------------------------------------------------
logimind_raw_dir() {
    local type="$1"
    case "$type" in
        article)  echo "$LOGIMIND_ARTICLES" ;;
        podcast)  echo "$LOGIMIND_PODCASTS" ;;
        tweet)    echo "$LOGIMIND_TWEETS" ;;
        voice)    echo "$LOGIMIND_VOICE" ;;
        image)    echo "$LOGIMIND_IMAGES" ;;
        file)     echo "$LOGIMIND_FILES" ;;
        chat)     echo "$LOGIMIND_CHATS" ;;
        task)     echo "$LOGIMIND_RAW" ;;
        *)        echo "$LOGIMIND_ARTICLES" ;;
    esac
}

#-------------------------------------------------------------------------------
# 追加到 All-Sources.md
#-------------------------------------------------------------------------------
logimind_append_sources() {
    local type="$1"
    local slug="$2"
    local title="${3:-}"
    local author="${4:-}"
    local source_url="${5:-}"
    local clipped_at="$(date +%Y-%m-%d)"

    local index_file="$LOGIMIND_INDEXES/All-Sources.md"
    if [[ ! -f "$index_file" ]]; then
        cat > "$index_file" <<'HEADER'
# 全部来源索引

> 自动维护。每次编译后由 LLM 更新。

| ID | 标题 | 作者 | 类型 | 来源URL | 添加日期 | 编译状态 | PARA |
|----|------|------|------|---------|----------|----------|------|
HEADER
    fi

    local id
    id="$(date +%Y%m%d%H%M%S)"
    echo "| $id | ${title:-${slug}} | ${author:-} | $type | $source_url | $clipped_at | raw | |" >> "$index_file"
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
# 主逻辑
#-------------------------------------------------------------------------------
main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: logimind ingest <URL> [type]" >&2
        echo "  type: article | podcast | tweet | voice | image | file | chat | task" >&2
        echo "        (auto-detected if not specified)" >&2
        exit 1
    fi

    local url="$1"
    local override_type="${2:-}"

    # 前置检查
    logimind_ensure_dirs || exit 1

    # 检测或使用指定类型
    local type
    if [[ -n "$override_type" ]]; then
        type="$override_type"
    else
        type="$(logimind_detect_type "$url")"
    fi

    # 抓取内容（使用 fetch_content.sh）
    echo "Fetching $url (type: $type)..."
    local content
    content="$("$SCRIPT_DIR/fetch_content.sh" "$url")" || {
        echo "ERROR: Failed to fetch $url" >&2
        exit 1
    }

    # 生成文件名
    local date_str
    date_str="$(date +%Y-%m-%d)"
    local slug
    slug="$(logimind_slug "$url")"
    local filename="${date_str}-${slug}"

    # 确定 raw 目录
    local raw_subdir
    raw_subdir="$(logimind_raw_dir "$type")"
    local dest_file="${raw_subdir}/${filename}.md"

    # 提取标题（从 content 首行或 url）
    local title="$slug"

    # 写入文件（含 frontmatter）
    {
        echo '---'
        echo "source_url: \"$url\""
        echo "author: \"\""
        echo "published: \"\""
        echo "clipped_at: \"$date_str\""
        echo "tags: []"
        echo "type: $type"
        echo "status: raw"
        echo '---'
        echo ""
        echo '> 原始资料，不做修改。编译产物见 wiki/summaries/ 对应文件。'
        echo ""
        echo "$content"
    } > "$dest_file"

    # 更新索引和日志
    logimind_append_sources "$type" "$filename" "$title" "" "$url"
    logimind_append_log "ingest" "URL: $url → $dest_file (type: $type)"

    echo "✓ Saved to $dest_file"
    echo ""
    echo "Next: Run 'logimind compile' to process this content"
}

main "$@"
