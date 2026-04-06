#!/usr/bin/env bash
#===============================================================================
# LogiMind — 主入口 CLI
# Usage: logimind <command> [args]
#===============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 加载配置
# shellcheck source=config.sh
source "$SKILL_DIR/config.sh"

#-------------------------------------------------------------------------------
# 用法说明
#-------------------------------------------------------------------------------
usage() {
    cat <<EOF
LogiMind — LLM Wiki 知识管理系统

用法:
  logimind <command> [args]

命令:
  ingest <URL> [type]  抓取 URL 到 raw/
                           type: article | podcast | tweet (auto-detected)
                           ⚠️ WeChat/微信公众号需登录，请用 ingest-text 粘贴正文
  ingest-text <file>   摄入本地文件或粘贴内容到 raw/
                           用途: WeChat 文章无法直接抓取时代替方案
                           用法: cat article.md | logimind ingest-text
                                 logimind ingest-text /path/to/file.md
  compile [file]        编译 raw/ 内容到 wiki/summaries/ + PARA 分类
                           不指定 file 则扫描所有未编译文件
  lint [--fix] [quick|full]
                           健康检查，默认 quick
                           --fix: 自动修复可修复问题
                           quick: 快速检查（默认）
                           full: 完整检查（一致性+完整性+孤岛）
  query <问题>          知识问答 → outputs/qa/

示例:
  logimind ingest https://example.com/article
  logimind ingest https://twitter.com/user/status/123 tweet
  logimind ingest-text ~/Downloads/article.md  # 本地文件
  cat article.md | logimind ingest-text        # 管道输入（粘贴内容）
  logimind compile
  logimind compile raw/articles/2026-04-06-my-article.md
  logimind lint
  logimind lint --fix
  logimind lint full
  logimind query 为什么 LLM Wiki 比 RAG 更好？

文档:
  SKILL.md   - $SKILL_DIR/SKILL.md
  CLAUDE.md  - $SKILL_DIR/CLAUDE.md
EOF
}

#-------------------------------------------------------------------------------
# 主逻辑
#-------------------------------------------------------------------------------
main() {
    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        ingest)
            "$SCRIPT_DIR/ingest.sh" "$@"
            ;;
        ingest-text)
            "$SCRIPT_DIR/ingest_text.sh" "$@"
            ;;
        compile)
            "$SCRIPT_DIR/compile.sh" "$@"
            ;;
        lint)
            "$SCRIPT_DIR/lint.sh" "$@"
            ;;
        query)
            "$SCRIPT_DIR/query.sh" "$@"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo "ERROR: unknown command '$cmd'" >&2
            usage >&2
            exit 1
            ;;
    esac
}

main "$@"
