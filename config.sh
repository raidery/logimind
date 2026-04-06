#!/usr/bin/env bash
#===============================================================================
# LogiMind Config — vault 路径与环境检查
#===============================================================================

# Vault 根目录
export LOGIMIND_VAULT="${LOGIMIND_VAULT:-$HOME/documents/second-brain}"

# Raw 素材目录
export LOGIMIND_RAW="$LOGIMIND_VAULT/raw"
export LOGIMIND_WIKI="$LOGIMIND_VAULT/wiki"
export LOGIMIND_OUTPUTS="$LOGIMIND_VAULT/outputs"

# Raw 子目录
export LOGIMIND_ARTICLES="$LOGIMIND_RAW/articles"
export LOGIMIND_PODCASTS="$LOGIMIND_RAW/podcasts"
export LOGIMIND_TWEETS="$LOGIMIND_RAW/tweets"
export LOGIMIND_VOICE="$LOGIMIND_RAW/voice"
export LOGIMIND_IMAGES="$LOGIMIND_RAW/images"
export LOGIMIND_FILES="$LOGIMIND_RAW/files"
export LOGIMIND_CHATS="$LOGIMIND_RAW/chats"

# Wiki 子目录（LLM 编译产物）
export LOGIMIND_SUMMARIES="$LOGIMIND_WIKI/summaries"
export LOGIMIND_CONCEPTS="$LOGIMIND_WIKI/concepts"
export LOGIMIND_INDEXES="$LOGIMIND_WIKI/indexes"

# PARA 分类目录
export LOGIMIND_PROJECTS="$LOGIMIND_WIKI/projects"    # 有目标+截止日期
export LOGIMIND_AREAS="$LOGIMIND_WIKI/areas"          # 持续责任
export LOGIMIND_RESOURCES="$LOGIMIND_WIKI/resources"  # 感兴趣暂无行动
export LOGIMIND_ARCHIVES="$LOGIMIND_WIKI/archives"   # 已完成/放弃

# Outputs
export LOGIMIND_QA="$LOGIMIND_OUTPUTS/qa"
export LOGIMIND_HEALTH="$LOGIMIND_OUTPUTS/health"

#-------------------------------------------------------------------------------
# 前置检查：vault 目录存在
#-------------------------------------------------------------------------------
logimind_check_vault() {
    if [[ ! -d "$LOGIMIND_VAULT" ]]; then
        echo "ERROR: Vault not found at $LOGIMIND_VAULT" >&2
        echo "Please create it or set LOGIMIND_VAULT environment variable." >&2
        return 1
    fi
    return 0
}

#-------------------------------------------------------------------------------
# 前置检查：必要子目录存在（不存在则创建）
#-------------------------------------------------------------------------------
logimind_ensure_dirs() {
    logimind_check_vault || return 1
    local dirs=(
        "$LOGIMIND_ARTICLES"
        "$LOGIMIND_PODCASTS"
        "$LOGIMIND_TWEETS"
        "$LOGIMIND_VOICE"
        "$LOGIMIND_IMAGES"
        "$LOGIMIND_FILES"
        "$LOGIMIND_CHATS"
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
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
        fi
    done
    return 0
}

#-------------------------------------------------------------------------------
# 检测 Obsidian CLI 是否可用
#-------------------------------------------------------------------------------
logimind_obsidian_available() {
    if command -v obsidian &>/dev/null; then
        return 0
    fi
    return 1
}

#-------------------------------------------------------------------------------
# PARA 判断：根据内容特征返回分类
# $1: content_type (article/podcast/tweet/voice/image/file/chat/task)
# $2: has_deadline ("yes"/"no")
# $3: has_action ("yes"/"no")
# 输出: projects | areas | resources | archives
#-------------------------------------------------------------------------------
logimind_para_classify() {
    local content_type="$1"
    local has_deadline="${2:-no}"
    local has_action="${3:-no}"

    if [[ "$has_deadline" == "yes" ]] || [[ "$has_action" == "yes" ]]; then
        echo "projects"
    elif [[ "$content_type" == "chat" ]] || [[ "$content_type" == "voice" ]]; then
        echo "areas"
    elif [[ "$content_type" == "image" ]] || [[ "$content_type" == "file" ]]; then
        echo "resources"
    else
        echo "resources"
    fi
}
