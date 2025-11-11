#!/bin/bash
#############################################################################
# Jimi 一键安装脚本
# 用途：自动完成环境检查、依赖安装、项目构建、配置初始化等所有步骤
# 作者：Jimi Team
#############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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

log_step() {
    echo -e "${MAGENTA}[STEP]${NC} $1"
}

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 显示欢迎信息
clear
echo -e "${CYAN}"
cat << "EOF"
    ╔═══════════════════════════════════════╗
    ║                                       ║
    ║                                       ║
    ║              Jimi 一键安装向导         ║
    ║                                       ║
    ║                                       ║
    ║                                       ║
    ╚═══════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""
echo "此脚本将引导您完成 Jimi 的安装和配置"
echo ""
echo "安装步骤："
echo "  1. 环境检查"
echo "  2. 依赖安装（如需要）"
echo "  3. 项目构建"
echo "  4. 配置初始化"
echo "  5. 启动 Jimi"
echo ""
read -p "按 Enter 键继续..." 

# 记录安装开始时间
INSTALL_START_TIME=$(date +%s)

# 步骤 1: 环境检查
echo ""
log_step "步骤 1/5: 环境检查"
echo ""

if [ -f "$SCRIPT_DIR/check-env.sh" ]; then
    bash "$SCRIPT_DIR/check-env.sh" || {
        ENV_CHECK_FAILED=true
        log_warning "环境检查发现问题"
    }
else
    log_error "未找到环境检查脚本"
    exit 1
fi

# 步骤 2: 依赖安装（如果需要）
echo ""
if [ "$ENV_CHECK_FAILED" = true ]; then
    log_step "步骤 2/5: 依赖安装"
    echo ""
    log_info "检测到缺少必要的依赖"
    read -p "是否自动安装缺少的依赖？[y/N] " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "$SCRIPT_DIR/install-deps.sh" ]; then
            bash "$SCRIPT_DIR/install-deps.sh" || {
                log_error "依赖安装失败"
                exit 1
            }
        else
            log_error "未找到依赖安装脚本"
            exit 1
        fi
        
        # 重新检查环境
        log_info "重新检查环境..."
        bash "$SCRIPT_DIR/check-env.sh" || {
            log_error "环境仍然不满足要求，请手动解决依赖问题"
            exit 1
        }
    else
        log_error "请手动安装依赖后重新运行此脚本"
        exit 1
    fi
else
    log_step "步骤 2/5: 依赖检查"
    log_success "所有依赖已满足，跳过安装步骤"
fi

# 步骤 3: 项目构建
echo ""
log_step "步骤 3/5: 项目构建"
echo ""

# 检查是否已经构建过
JAR_FILE=$(find "$PROJECT_DIR/target" -name "jimi-*.jar" -not -name "*-sources.jar" 2>/dev/null | head -n 1)

if [ -n "$JAR_FILE" ]; then
    log_info "检测到已存在的构建产物: $(basename "$JAR_FILE")"
    read -p "是否重新构建？[y/N] " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_success "跳过构建步骤"
        BUILD_SKIPPED=true
    fi
fi

if [ "$BUILD_SKIPPED" != true ]; then
    if [ -f "$SCRIPT_DIR/build.sh" ]; then
        log_info "开始构建项目（首次构建可能需要几分钟下载依赖）..."
        echo ""
        
        bash "$SCRIPT_DIR/build.sh" --skip-tests || {
            log_error "项目构建失败"
            log_info "您可以尝试："
            echo "  1. 检查网络连接"
            echo "  2. 手动运行: ./scripts/build.sh"
            echo "  3. 清理后重试: ./scripts/build.sh --clean"
            exit 1
        }
    else
        log_error "未找到构建脚本"
        exit 1
    fi
fi

# 步骤 4: 配置初始化
echo ""
log_step "步骤 4/5: 配置初始化"
echo ""

CONFIG_FILE="$HOME/.jimi/config.json"

if [ -f "$CONFIG_FILE" ]; then
    log_info "检测到已存在的配置文件"
    read -p "是否重新配置？[y/N] " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_success "使用现有配置"
        CONFIG_SKIPPED=true
    fi
fi

if [ "$CONFIG_SKIPPED" != true ]; then
    if [ -f "$SCRIPT_DIR/init-config.sh" ]; then
        bash "$SCRIPT_DIR/init-config.sh" || {
            log_error "配置初始化失败"
            exit 1
        }
    else
        log_error "未找到配置初始化脚本"
        exit 1
    fi
fi

# 步骤 5: 启动 Jimi
echo ""
log_step "步骤 5/5: 启动 Jimi"
echo ""

# 计算总安装时间
INSTALL_END_TIME=$(date +%s)
INSTALL_DURATION=$((INSTALL_END_TIME - INSTALL_START_TIME))

# 显示安装摘要
echo -e "${GREEN}"
cat << "EOF"
    ╔═══════════════════════════════════════╗
    ║                                       ║
    ║        安装成功完成！                  ║
    ║                                       ║
    ╚═══════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""
log_success "安装耗时: ${INSTALL_DURATION}s"
echo ""
echo "========================================"
echo "   安装摘要"
echo "========================================"
echo "项目目录: $PROJECT_DIR"
echo "配置文件: $CONFIG_FILE"
echo "会话目录: $HOME/.jimi/sessions"
echo "日志目录: $HOME/.jimi/logs"
echo "========================================"
echo ""

# 创建便捷启动别名建议
echo -e "${CYAN}提示：${NC}您可以将以下别名添加到您的 shell 配置文件中（~/.zshrc 或 ~/.bash_profile）："
echo ""
echo "alias jimi='$SCRIPT_DIR/start.sh'"
echo ""

# 询问是否立即启动
log_info "准备启动 Jimi..."
read -p "是否立即启动？[Y/n] " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo ""
    log_success "正在启动 Jimi..."
    echo ""
    
    if [ -f "$SCRIPT_DIR/start.sh" ]; then
        bash "$SCRIPT_DIR/start.sh"
    else
        log_error "未找到启动脚本"
        exit 1
    fi
else
    echo ""
    log_info "您可以随时运行以下命令启动 Jimi："
    echo "  ./scripts/start.sh"
    echo ""
    log_info "或者使用完整路径："
    echo "  cd $PROJECT_DIR && ./scripts/start.sh"
    echo ""
    log_success "感谢使用 Jimi！"
fi
