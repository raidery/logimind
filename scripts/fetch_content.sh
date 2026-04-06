#!/usr/bin/env bash
#===============================================================================
# LogiMind — fetch_content.sh
# 智能识别平台并获取内容，优先使用专用工具，fallback 到 Jina Reader
# Usage: fetch_content.sh <url> [output_file]
#===============================================================================

set -euo pipefail

URL="$1"
OUTPUT_FILE="${2:-}"

if [[ -z "$URL" ]]; then
    echo "Usage: $0 <url> [output_file]" >&2
    echo "" >&2
    echo "Supported platforms:" >&2
    echo "  Twitter/X     - https://x.com/... or https://twitter.com/..." >&2
    echo "  YouTube      - https://youtube.com/... or https://youtu.be/..." >&2
    echo "  Bilibili     - https://bilibili.com/..." >&2
    echo "  微信公众号    - https://mp.weixin.qq.com/..." >&2
    echo "  小红书       - https://www.xiaohongshu.com/..." >&2
    echo "  普通网页     - 任何 http/https URL (via Jina Reader)" >&2
    exit 1
fi

#-------------------------------------------------------------------------------
# 检测平台
#-------------------------------------------------------------------------------
detect_platform() {
    if [[ "$URL" =~ (x\.com|twitter\.com) ]]; then
        echo "twitter"
    elif [[ "$URL" =~ (youtube\.com|youtu\.be) ]]; then
        echo "youtube"
    elif [[ "$URL" =~ bilibili\.com|b23\.tv ]]; then
        echo "bilibili"
    elif [[ "$URL" =~ mp\.weixin\.qq\.com ]]; then
        echo "wechat"
    elif [[ "$URL" =~ xiaohongshu\.com ]]; then
        echo "xiaohongshu"
    else
        echo "generic"
    fi
}

#-------------------------------------------------------------------------------
# Twitter/X — Jina Reader
#-------------------------------------------------------------------------------
fetch_twitter() {
    local jina_url="https://r.jina.ai/${URL}"
    echo "Fetching Twitter/X via Jina Reader..." >&2
    curl -s --fail --max-time 30 "$jina_url"
}

#-------------------------------------------------------------------------------
# YouTube — yt-dlp 字幕
#-------------------------------------------------------------------------------
fetch_youtube() {
    echo "Fetching YouTube via yt-dlp..." >&2
    if ! command -v yt-dlp &>/dev/null; then
        echo "ERROR: yt-dlp not installed" >&2
        echo "Install: brew install yt-dlp or pip install yt-dlp" >&2
        return 1
    fi

    local extra_args=()
    if [[ -n "$OUTPUT_FILE" ]]; then
        extra_args=(-o "$OUTPUT_FILE")
    fi

    # Try Chinese subtitles first, then English
    yt-dlp --write-auto-sub --sub-lang zh-Hans,en --skip-download \
        --print "%(title)s\n\n%(description)s\n\n[Transcript]\n%(subtitles)s" \
        "$URL" "${extra_args[@]}" 2>/dev/null
}

#-------------------------------------------------------------------------------
# Bilibili — yt-dlp 中文字幕
#-------------------------------------------------------------------------------
fetch_bilibili() {
    echo "Fetching Bilibili via yt-dlp..." >&2
    if ! command -v yt-dlp &>/dev/null; then
        echo "ERROR: yt-dlp not installed" >&2
        return 1
    fi

    local extra_args=()
    if [[ -n "$OUTPUT_FILE" ]]; then
        extra_args=(-o "$OUTPUT_FILE")
    fi

    yt-dlp --write-auto-sub --sub-lang zh-Hans --skip-download \
        --print "%(title)s\n\n%(description)s" \
        "$URL" "${extra_args[@]}" 2>/dev/null
}

#-------------------------------------------------------------------------------
# 微信公众号 / 小红书 — agent-reach 或 Jina Reader
#-------------------------------------------------------------------------------
fetch_wechat_or_xiaohongshu() {
    echo "Fetching via agent-reach (or Jina Reader fallback)..." >&2

    if command -v agent-reach &>/dev/null; then
        agent-reach --read "$URL"
    else
        # Fallback to Jina Reader
        local jina_url="https://r.jina.ai/${URL}"
        curl -s --fail --max-time 30 "$jina_url"
    fi
}

#-------------------------------------------------------------------------------
# 普通网页 — Jina Reader
#-------------------------------------------------------------------------------
fetch_generic() {
    echo "Fetching via Jina Reader..." >&2
    local jina_url="https://r.jina.ai/${URL}"
    curl -s --fail --max-time 30 "$jina_url"
}

#-------------------------------------------------------------------------------
# 主逻辑
#-------------------------------------------------------------------------------
PLATFORM=$(detect_platform)

echo "Platform: $PLATFORM" >&2
echo "URL: $URL" >&2

case "$PLATFORM" in
    twitter)
        fetch_twitter
        ;;
    youtube)
        fetch_youtube
        ;;
    bilibili)
        fetch_bilibili
        ;;
    wechat|xiaohongshu)
        fetch_wechat_or_xiaohongshu
        ;;
    generic)
        fetch_generic
        ;;
esac
