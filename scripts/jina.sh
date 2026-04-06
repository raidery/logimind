#!/usr/bin/env bash
#===============================================================================
# LogiMind — Jina Reader 封装（简单版）
# 直接调用 Jina Reader 将 URL 转成 markdown
# 优先使用 fetch_content.sh（支持多平台），本文件保留用于简单场景
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# Jina Reader 抓取
# $1: URL
# 输出: markdown 内容
#-------------------------------------------------------------------------------
logimind_jina_fetch() {
    local url="$1"
    if [[ -z "$url" ]]; then
        echo "ERROR: URL required" >&2
        return 1
    fi

    local jina_url="https://r.jina.ai/${url}"
    local response
    response="$(curl -s --fail --max-time 30 "$jina_url" 2>/dev/null)" || {
        echo "ERROR: Jina fetch failed for $url" >&2
        return 1
    }

    echo "$response"
}

#-------------------------------------------------------------------------------
# 检测内容类型
# $1: URL
# 输出: article | podcast | tweet
#-------------------------------------------------------------------------------
logimind_detect_type() {
    local url="$1"
    local lower_url
    lower_url="$(echo "$url" | tr '[:upper:]' '[:lower:]')"

    if echo "$lower_url" | grep -qE '(youtube\.com|bilibili\.com|b23\.tv|podcast|spotify\.com)'; then
        echo "podcast"
    elif echo "$lower_url" | grep -qE '(twitter\.com|x\.com)'; then
        echo "tweet"
    else
        echo "article"
    fi
}

# 如果直接运行此脚本（调试模式）
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <URL>" >&2
        exit 1
    fi
    logimind_jina_fetch "$1"
fi
