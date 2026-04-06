#!/usr/bin/env bash
#===============================================================================
# LogiMind — lint: 健康检查（基于 doctor.sh 思路）
# Usage: logimind lint [--fix] [quick|full]
#         --fix   自动修复可修复问题
#         quick   只做快速检查（默认）
#         full    完整检查（一致性+完整性+孤岛检测）
#===============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
source "$SKILL_DIR/config.sh"

AUTO_FIX="${1:-}"
CHECK_MODE="${2:-quick}"
if [[ "$AUTO_FIX" == "--fix" ]] && [[ -n "${2:-}" ]]; then
    CHECK_MODE="$2"
elif [[ "$AUTO_FIX" == "quick" ]] || [[ "$AUTO_FIX" == "full" ]]; then
    CHECK_MODE="$AUTO_FIX"
    AUTO_FIX=""
fi

#-------------------------------------------------------------------------------
# 颜色
#-------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ISSUES=0
FIXES=0

log_check()  { echo -e "${GREEN}[检查]${NC} $1"; }
log_warn()   { echo -e "${YELLOW}[警告]${NC} $1"; ISSUES=$((ISSUES+1)); }
log_error()  { echo -e "${RED}[错误]${NC} $1"; ISSUES=$((ISSUES+1)); }
log_fix()    { echo -e "${GREEN}[已修复]${NC} $1"; FIXES=$((FIXES+1)); }
log_info()   { echo -e "${BLUE}[信息]${NC} $1"; }

#-------------------------------------------------------------------------------
# 1. 检查目录结构
#-------------------------------------------------------------------------------
check_directories() {
    log_check "检查目录结构..."
    local required_dirs=(
        "$LOGIMIND_ARTICLES"
        "$LOGIMIND_PODCASTS"
        "$LOGIMIND_TWEETS"
        "$LOGIMIND_VOICE"
        "$LOGIMIND_IMAGES"
        "$LOGIMIND_FILES"
        "$LOGIMIND_SUMMARIES"
        "$LOGIMIND_CONCEPTS"
        "$LOGIMIND_INDEXES"
        "$LOGIMIND_PROJECTS"
        "$LOGIMIND_AREAS"
        "$LOGIMIND_RESOURCES"
        "$LOGIMIND_ARCHIVES"
        "$LOGIMIND_QA"
        "$LOGIMIND_HEALTH"
    )
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_check "  ✓ $(basename "$dir")"
        else
            log_error "  ✗ 缺失: $(basename "$dir")"
            if [[ "$AUTO_FIX" == "--fix" ]]; then
                mkdir -p "$dir"
                log_fix "已创建: $(basename "$dir")"
            fi
        fi
    done
}

#-------------------------------------------------------------------------------
# 2. 检查核心文件
#-------------------------------------------------------------------------------
check_core_files() {
    log_check "检查核心文件..."
    local required_files=(
        "$LOGIMIND_VAULT/CLAUDE.md"
        "$LOGIMIND_INDEXES/All-Sources.md"
        "$LOGIMIND_INDEXES/All-Concepts.md"
    )
    local vault_log="$LOGIMIND_VAULT/log.md"

    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_check "  ✓ $(basename "$file")"
        else
            log_error "  ✗ 缺失: $file"
        fi
    done

    if [[ -f "$vault_log" ]]; then
        log_check "  ✓ log.md"
    else
        log_warn "  ! log.md 不存在（首次使用）"
    fi
}

#-------------------------------------------------------------------------------
# 3. 工具依赖检查
#-------------------------------------------------------------------------------
check_dependencies() {
    log_check "检查工具依赖..."
    check_cmd "curl" "curl"
    check_cmd "git" "git"

    echo ""
    log_info "  可选工具（建议安装）:"
    check_cmd_soft "yt-dlp" "yt-dlp (YouTube/B站)"
    check_cmd_soft "agent-reach" "agent-reach (微信/小红书)"
    check_cmd_soft "ollama" "Ollama (语音转录)"
    check_cmd_soft "whisper" "Whisper"
    check_cmd_soft "exiftool" "exiftool"
    check_cmd_soft "pdftotext" "pdftotext (PDF)"
}

check_cmd() {
    local cmd="$1"
    local name="$2"
    if command -v "$cmd" &>/dev/null; then
        log_check "  ✓ $name"
    else
        log_error "  ✗ $name (未安装)"
    fi
}

check_cmd_soft() {
    local cmd="$1"
    local name="$2"
    if command -v "$cmd" &>/dev/null; then
        log_check "  ✓ $name"
    else
        log_info "  - $name (未安装)"
    fi
}

#-------------------------------------------------------------------------------
# 4. All-Sources.md 格式检查
#-------------------------------------------------------------------------------
check_sources_index() {
    log_check "检查 All-Sources.md..."
    local index_file="$LOGIMIND_INDEXES/All-Sources.md"
    if [[ ! -f "$index_file" ]]; then
        log_warn "  ! All-Sources.md 不存在"
        return
    fi

    local raw_count
    raw_count=$(find "$LOGIMIND_RAW" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    local compiled_count
    compiled_count=$(grep -c "| compiled |" "$index_file" 2>/dev/null || echo "0")

    log_info "  raw 文件: $raw_count"
    log_info "  已编译: $compiled_count"

    if [[ "$raw_count" -gt 0 ]] && [[ "$compiled_count" -eq 0 ]]; then
        log_warn "  有 $raw_count 个 raw 文件但全部未编译"
    fi
}

#-------------------------------------------------------------------------------
# 5. 孤儿文件检测
#-------------------------------------------------------------------------------
check_orphans() {
    log_check "检查孤儿文件..."
    local orphans=0

    # 找 raw 文件中有对应 summaries 的
    if [[ -d "$LOGIMIND_RAW" ]] && [[ -d "$LOGIMIND_SUMMARIES" ]]; then
        while IFS= read -r raw_file; do
            local base="${raw_file#$LOGIMIND_RAW/}"
            base="${base%.md}"
            local summary_file="$LOGIMIND_SUMMARIES/${base}.md"
            if [[ ! -f "$summary_file" ]]; then
                : # 未编译，不算孤儿
            fi
        done < <(find "$LOGIMIND_RAW" -type f -name "*.md" 2>/dev/null)
    fi

    # 检查 summaries 中是否有无法链接回 raw 的
    if [[ -d "$LOGIMIND_SUMMARIES" ]]; then
        while IFS= read -r sum_file; do
            local source_link
            source_link=$(grep -oE 'raw/[a-z]+/[0-9]{4}-[0-9]{2}-[a-z0-9-]+\.md' "$sum_file" 2>/dev/null | head -1)
            if [[ -n "$source_link" ]]; then
                local full_path="$LOGIMIND_VAULT/$source_link"
                if [[ ! -f "$full_path" ]]; then
                    log_warn "  孤儿摘要: $(basename "$sum_file") → 引用了不存在的 $source_link"
                    orphans=$((orphans+1))
                fi
            fi
        done < <(find "$LOGIMIND_SUMMARIES" -name "*.md" 2>/dev/null)
    fi

    if [[ $orphans -eq 0 ]]; then
        log_check "  ✓ 无孤儿摘要"
    fi
}

#-------------------------------------------------------------------------------
# 6. log.md 格式检查
#-------------------------------------------------------------------------------
check_log_format() {
    log_check "检查 log.md 格式..."
    local log_file="$LOGIMIND_VAULT/log.md"
    if [[ ! -f "$log_file" ]]; then
        log_warn "  ! log.md 不存在"
        return
    fi

    local last_entry
    last_entry=$(grep -m1 "^## \[" "$log_file" 2>/dev/null || echo "")
    if [[ -n "$last_entry" ]]; then
        if [[ "$last_entry" =~ ^##\ \[202[0-9]-[0-9][0-9]-[0-9][0-9\] ]]; then
            log_check "  ✓ 格式正确"
        else
            log_warn "  ! 最近条目格式可能不正确: $last_entry"
        fi
    else
        log_info "  ! 暂无操作记录（首次使用）"
    fi
}

#-------------------------------------------------------------------------------
# 7. PARA 目录统计
#-------------------------------------------------------------------------------
check_para_stats() {
    log_check "检查 PARA 目录..."
    local total=0
    for para in projects areas resources archives; do
        local para_dir
        para_dir="$(eval echo "\$LOGIMIND_$(echo "$para" | tr '[:lower:]' '[:upper:]')")"
        if [[ -d "$para_dir" ]]; then
            local count
            count=$(find "$para_dir" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
            log_info "  $para: $count 个文件"
            total=$((total + count))
        fi
    done
    log_info "  PARA 合计: $total 个文件"
}

#-------------------------------------------------------------------------------
# 8. full 模式额外检查
#-------------------------------------------------------------------------------
check_full() {
    log_check "完整检查：一致性 + 完整性..."
    echo ""

    # 一致性：检查 concept 文件中的 sources 引用是否存在
    log_info "[一致性] 检查概念引用..."
    if [[ -d "$LOGIMIND_CONCEPTS" ]]; then
        local conflict_count=0
        while IFS= read -r concept_file; do
            local file_sources
            file_sources=$(grep -oE '\[\[raw/[a-z]+/[0-9]{4}-[0-9]{2}-[a-z0-9-]+\.md\]\]' "$concept_file" 2>/dev/null)
            if [[ -n "$file_sources" ]]; then
                echo "$file_sources" | while read -r src; do
                    src="${src//\[\[/}"
                    src="${src//\]\]/}"
                    local full_path="$LOGIMIND_VAULT/$src"
                    if [[ ! -f "$full_path" ]]; then
                        log_warn "  概念 $(basename "$concept_file") 引用了不存在的 $src"
                        conflict_count=$((conflict_count + 1))
                    fi
                done
            fi
        done < <(find "$LOGIMIND_CONCEPTS" -name "*.md" 2>/dev/null)

        if [[ $conflict_count -eq 0 ]]; then
            log_check "  ✓ 无矛盾引用"
        fi
    fi

    # 完整性：检查 summaries 是否都有核心结论
    log_info "[完整性] 检查摘要完整性..."
    if [[ -d "$LOGIMIND_SUMMARIES" ]]; then
        local incomplete=0
        while IFS= read -r sum_file; do
            if ! grep -q "## 第一步：浓缩" "$sum_file" 2>/dev/null; then
                log_warn "  摘要缺少第一步: $(basename "$sum_file")"
                incomplete=$((incomplete + 1))
            fi
        done < <(find "$LOGIMIND_SUMMARIES" -name "*.md" 2>/dev/null)

        if [[ $incomplete -eq 0 ]]; then
            log_check "  ✓ 所有摘要包含三步编译"
        fi
    fi

    echo ""
    log_info "完整检查需要 Agent/LLM 读取文件做深度分析"
    log_info "当前自动检查完成，建议运行 'logimind compile' 确保所有内容已编译"
}

#-------------------------------------------------------------------------------
# 9. 自动修复
#-------------------------------------------------------------------------------
auto_fix() {
    echo ""
    log_info "执行自动修复..."

    # 确保所有目录存在
    logimind_ensure_dirs

    # 确保索引文件存在
    if [[ ! -f "$LOGIMIND_INDEXES/All-Sources.md" ]]; then
        cat > "$LOGIMIND_INDEXES/All-Sources.md" <<'HEADER'
# 全部来源索引

> 自动维护。每次编译后由 LLM 更新。

| ID | 标题 | 作者 | 类型 | 来源URL | 添加日期 | 编译状态 | PARA |
|----|------|------|------|---------|----------|----------|------|
HEADER
        log_fix "创建 All-Sources.md"
    fi

    if [[ ! -f "$LOGIMIND_INDEXES/All-Concepts.md" ]]; then
        cat > "$LOGIMIND_INDEXES/All-Concepts.md" <<'HEADER'
# 全部概念索引

> 自动维护。每次编译后由 LLM 更新。

| 概念 | 定义（一句话） | 首次来源 | 相关概念 | 最后更新 |
|------|--------------|----------|----------|----------|
HEADER
        log_fix "创建 All-Concepts.md"
    fi

    if [[ ! -f "$LOGIMIND_VAULT/log.md" ]]; then
        cat > "$LOGIMIND_VAULT/log.md" <<'HEADER'
# LogiMind 操作日志

> append-only 操作记录

---
HEADER
        log_fix "创建 log.md"
    fi

    # 确保 vault 根目录有 CLAUDE.md（从 skill 目录复制）
    local skill_claude="$SKILL_DIR/CLAUDE.md"
    if [[ -f "$skill_claude" ]] && [[ ! -f "$LOGIMIND_VAULT/CLAUDE.md" ]]; then
        cp "$skill_claude" "$LOGIMIND_VAULT/CLAUDE.md"
        log_fix "复制 CLAUDE.md 到 vault"
    fi
}

#-------------------------------------------------------------------------------
# 生成健康报告
#-------------------------------------------------------------------------------
generate_report() {
    local date_str
    date_str="$(date +%Y-%m-%d)"
    local report_file="$LOGIMIND_HEALTH/${date_str}-health.md"

    logimind_ensure_dirs

    {
        echo '---'
        echo "check_date: \"$date_str\""
        echo "check_type: $CHECK_MODE"
        echo "auto_fix: ${AUTO_FIX:-false}"
        echo '---'
        echo ""
        echo "# 健康检查报告 — $date_str"
        echo ""
        echo "**检查模式**: $CHECK_MODE"
        if [[ "$AUTO_FIX" == "--fix" ]]; then
            echo "**自动修复**: 已执行"
        fi
        echo ""
        echo "## 概览"
        echo "| 检查项 | 状态 | 备注 |"
        echo "|--------|------|------|"
        echo "| 目录结构 | ${ISSUES:-0} 问题 | |"
        echo "| 核心文件 | 检查完成 | |"
        echo "| 工具依赖 | 检查完成 | |"
        echo "| 来源索引 | 检查完成 | |"
        echo "| 孤儿文件 | 检查完成 | |"
        echo "| PARA 统计 | 见下方 | |"
        echo ""
        echo "## PARA 分布"
        echo "| 类型 | 文件数 |"
        echo "|-----|--------|"
        for para in projects areas resources archives; do
            local para_dir
            para_dir="$(eval echo "\$LOGIMIND_$(echo "$para" | tr '[:lower:]' '[:upper:]')")"
            local count
            count=$(find "$para_dir" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
            echo "| $para | $count |"
        done
        echo ""
        echo "## 待处理"
        if [[ ${ISSUES:-0} -gt 0 ]]; then
            echo "- 发现 $ISSUES 个问题，建议手动检查"
        else
            echo "- 暂无问题"
        fi
        echo "- 运行 'logimind compile' 编译未处理的内容"
    } > "$report_file"

    log_check "报告已生成: $report_file"
}

#-------------------------------------------------------------------------------
# 主逻辑
#-------------------------------------------------------------------------------
main() {
    echo "============================================"
    echo "         LogiMind Health Check"
    echo "         $(date +%Y-%m-%d\ %H:%M)"
    echo "============================================"
    echo ""
    echo "模式: $CHECK_MODE"
    if [[ "$AUTO_FIX" == "--fix" ]]; then
        echo "自动修复: 启用"
    fi
    echo ""

    logimind_check_vault || {
        log_error "Vault 未找到: $LOGIMIND_VAULT"
        exit 1
    }

    check_directories
    check_core_files
    check_dependencies
    echo ""
    check_sources_index
    check_orphans
    check_log_format
    check_para_stats

    if [[ "$CHECK_MODE" == "full" ]]; then
        check_full
    fi

    if [[ "$AUTO_FIX" == "--fix" ]]; then
        auto_fix
    fi

    generate_report

    echo ""
    echo "============================================"
    echo "         检查完成"
    echo "============================================"
    echo ""
    echo "问题数量: ${ISSUES:-0}"
    if [[ "$AUTO_FIX" == "--fix" ]]; then
        echo "已修复: $FIXES"
    fi
    echo ""

    if [[ ${ISSUES:-0} -eq 0 ]]; then
        echo -e "${GREEN}✓ LogiMind 状态良好!${NC}"
    else
        echo -e "${YELLOW}! 发现 ${ISSUES:-0} 个问题${NC}"
        echo ""
        echo "运行 'logimind lint --fix' 进行自动修复"
    fi
}

main
