#!/bin/bash
#############################################################################
# Jimi 配置初始化脚本
# 用途：引导用户完成 Jimi 的初始配置
# 作者：Jimi Team
#############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_question() {
    echo -e "${CYAN}[?]${NC} $1"
}

echo "========================================"
echo "   Jimi 配置初始化向导"
echo "========================================"
echo ""

# 获取项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$HOME/.jimi"
CONFIG_FILE="$CONFIG_DIR/config.json"

log_info "项目目录: $PROJECT_DIR"
log_info "配置目录: $CONFIG_DIR"

# 创建配置目录
if [ ! -d "$CONFIG_DIR" ]; then
    log_info "创建配置目录: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
    log_success "配置目录创建成功"
else
    log_success "配置目录已存在"
fi

# 检查是否已有配置文件
if [ -f "$CONFIG_FILE" ]; then
    log_warning "检测到已存在的配置文件: $CONFIG_FILE"
    read -p "是否覆盖现有配置？[y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "保留现有配置，退出初始化"
        exit 0
    fi
    # 备份现有配置
    BACKUP_FILE="$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    log_success "现有配置已备份到: $BACKUP_FILE"
fi

echo ""
echo "========================================"
echo "   LLM 服务提供商配置"
echo "========================================"
echo ""
log_info "Jimi 需要连接 LLM 服务才能正常工作"
echo ""
echo "支持的 LLM 提供商："
echo "  1. OpenAI (GPT-4, GPT-3.5-turbo)"
echo "  2. Moonshot (月之暗面)"
echo "  3. 其他兼容 OpenAI API 的服务"
echo ""

# 选择 LLM 提供商
read -p "请选择 LLM 提供商 [1-3, 默认: 2]: " LLM_PROVIDER
LLM_PROVIDER=${LLM_PROVIDER:-2}

# 根据选择设置默认值
case $LLM_PROVIDER in
    1)
        PROVIDER_NAME="openai"
        DEFAULT_BASE_URL="https://api.openai.com/v1"
        DEFAULT_MODEL="gpt-4"
        ;;
    2)
        PROVIDER_NAME="moonshot"
        DEFAULT_BASE_URL="https://api.moonshot.cn/v1"
        DEFAULT_MODEL="moonshot-v1-8k"
        ;;
    3)
        PROVIDER_NAME="custom"
        DEFAULT_BASE_URL="http://localhost:8080/v1"
        DEFAULT_MODEL="gpt-3.5-turbo"
        ;;
    *)
        log_error "无效的选择"
        exit 1
        ;;
esac

echo ""
# API Key
log_question "请输入 API Key:"
read -s API_KEY
echo ""

if [ -z "$API_KEY" ]; then
    log_error "API Key 不能为空"
    exit 1
fi

# API Base URL
echo ""
log_question "请输入 API Base URL [默认: $DEFAULT_BASE_URL]:"
read BASE_URL
BASE_URL=${BASE_URL:-$DEFAULT_BASE_URL}

# 模型名称
echo ""
log_question "请输入模型名称 [默认: $DEFAULT_MODEL]:"
read MODEL_NAME
MODEL_NAME=${MODEL_NAME:-$DEFAULT_MODEL}

echo ""
echo "========================================"
echo "   高级配置（可选）"
echo "========================================"
echo ""

# 循环控制配置
read -p "最大执行步数 [默认: 50]: " MAX_STEPS
MAX_STEPS=${MAX_STEPS:-50}

read -p "最大运行时间(秒) [默认: 3600]: " MAX_RUNTIME
MAX_RUNTIME=${MAX_RUNTIME:-3600}

# 是否启用 Skills 功能
echo ""
read -p "是否启用 Skills 功能？[y/N]: " -n 1 -r
echo
ENABLE_SKILLS="false"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ENABLE_SKILLS="true"
fi

# 生成配置文件
echo ""
log_info "生成配置文件..."

cat > "$CONFIG_FILE" <<EOF
{
  "llm": {
    "providers": {
      "$PROVIDER_NAME": {
        "apiKey": "$API_KEY",
        "baseUrl": "$BASE_URL"
      }
    },
    "defaultProvider": "$PROVIDER_NAME",
    "defaultModel": "$MODEL_NAME"
  },
  "loopControl": {
    "maxSteps": $MAX_STEPS,
    "maxRuntime": $MAX_RUNTIME
  },
  "features": {
    "enableSkills": $ENABLE_SKILLS,
    "enableApproval": false,
    "enableYoloMode": false
  }
}
EOF

log_success "配置文件已生成: $CONFIG_FILE"

# 创建会话目录
SESSION_DIR="$CONFIG_DIR/sessions"
if [ ! -d "$SESSION_DIR" ]; then
    mkdir -p "$SESSION_DIR"
    log_success "会话目录已创建: $SESSION_DIR"
fi

# 创建日志目录
LOG_DIR="$CONFIG_DIR/logs"
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
    log_success "日志目录已创建: $LOG_DIR"
fi

# 输出配置摘要
echo ""
echo "========================================"
echo "   配置摘要"
echo "========================================"
echo ""
echo "LLM 提供商: $PROVIDER_NAME"
echo "API Base URL: $BASE_URL"
echo "模型名称: $MODEL_NAME"
echo "最大执行步数: $MAX_STEPS"
echo "最大运行时间: ${MAX_RUNTIME}s"
echo "Skills 功能: $ENABLE_SKILLS"
echo ""
echo "配置文件: $CONFIG_FILE"
echo "会话目录: $SESSION_DIR"
echo "日志目录: $LOG_DIR"
echo ""

log_success "配置初始化完成！"
echo ""
log_info "提示："
echo "  - 可以手动编辑配置文件: $CONFIG_FILE"
echo "  - 配置文件使用 JSON 格式"
echo "  - 更多配置选项请参考文档"
echo ""
log_info "下一步："
echo "  运行 ./scripts/start.sh 启动 Jimi"
echo ""

# 询问是否立即启动
read -p "是否立即启动 Jimi？[y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "启动 Jimi..."
    exec "$SCRIPT_DIR/start.sh"
fi
