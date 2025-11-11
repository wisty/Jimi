#!/bin/bash
#############################################################################
# Jimi 环境检查脚本
# 用途：检查系统环境是否满足 Jimi 运行要求
# 作者：Jimi Team
#############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查结果统计
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

echo "========================================"
echo "   Jimi 环境检查工具"
echo "========================================"
echo ""

# 1. 检查操作系统
log_info "检查操作系统..."
OS_TYPE=$(uname -s)
case "$OS_TYPE" in
    Darwin*)
        log_success "操作系统: macOS"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        ;;
    Linux*)
        log_success "操作系统: Linux"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        ;;
    *)
        log_warning "操作系统: $OS_TYPE (未测试的系统)"
        CHECKS_WARNING=$((CHECKS_WARNING + 1))
        ;;
esac

# 2. 检查 Java 环境
log_info "检查 Java 环境..."
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
    JAVA_FULL_VERSION=$(java -version 2>&1 | head -n 1)
    
    if [ "$JAVA_VERSION" -ge 17 ]; then
        log_success "Java 版本: $JAVA_FULL_VERSION"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        log_error "Java 版本过低: $JAVA_FULL_VERSION (需要 Java 17 或更高版本)"
        CHECKS_FAILED=$((CHECKS_FAILED + 1))
    fi
else
    log_error "未找到 Java 环境，请安装 Java 17 或更高版本"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# 3. 检查 JAVA_HOME 环境变量
log_info "检查 JAVA_HOME 环境变量..."
if [ -n "$JAVA_HOME" ]; then
    log_success "JAVA_HOME: $JAVA_HOME"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    
    # 验证 JAVA_HOME 路径是否存在
    if [ ! -d "$JAVA_HOME" ]; then
        log_warning "JAVA_HOME 路径不存在: $JAVA_HOME"
        CHECKS_WARNING=$((CHECKS_WARNING + 1))
    fi
else
    log_warning "JAVA_HOME 未设置（建议设置）"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
    
    # 尝试自动查找 Java 17
    if [[ "$OS_TYPE" == "Darwin"* ]]; then
        if command -v /usr/libexec/java_home &> /dev/null; then
            SUGGESTED_JAVA_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null || echo "")
            if [ -n "$SUGGESTED_JAVA_HOME" ]; then
                log_info "建议设置: export JAVA_HOME=$SUGGESTED_JAVA_HOME"
            fi
        fi
    fi
fi

# 4. 检查 Maven
log_info "检查 Maven..."
if command -v mvn &> /dev/null; then
    MVN_VERSION=$(mvn -version | head -n 1)
    log_success "Maven: $MVN_VERSION"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    log_error "未找到 Maven，请安装 Maven 3.6 或更高版本"
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

# 5. 检查 Git
log_info "检查 Git..."
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    log_success "$GIT_VERSION"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    log_warning "未找到 Git（可选，但建议安装）"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
fi

# 6. 检查磁盘空间
log_info "检查磁盘空间..."
if [[ "$OS_TYPE" == "Darwin"* ]]; then
    AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
else
    AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
fi
log_success "可用磁盘空间: $AVAILABLE_SPACE"
CHECKS_PASSED=$((CHECKS_PASSED + 1))

# 7. 检查内存
log_info "检查系统内存..."
if [[ "$OS_TYPE" == "Darwin"* ]]; then
    TOTAL_MEM=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    log_success "系统总内存: ${TOTAL_MEM}GB"
else
    TOTAL_MEM=$(free -g | awk '/^Mem:/ {print $2}')
    log_success "系统总内存: ${TOTAL_MEM}GB"
fi
CHECKS_PASSED=$((CHECKS_PASSED + 1))

# 8. 检查网络连接
log_info "检查网络连接..."
if ping -c 1 maven.aliyun.com &> /dev/null || ping -c 1 repo.maven.apache.org &> /dev/null; then
    log_success "网络连接正常"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    log_warning "网络连接可能存在问题（构建时可能需要网络）"
    CHECKS_WARNING=$((CHECKS_WARNING + 1))
fi

# 9. 检查 Shell 环境
log_info "检查 Shell 环境..."
SHELL_TYPE=$(echo $SHELL)
log_success "Shell: $SHELL_TYPE"
CHECKS_PASSED=$((CHECKS_PASSED + 1))

# 10. 检查必要的命令工具
log_info "检查必要的命令工具..."
REQUIRED_COMMANDS=("curl" "unzip")
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if command -v $cmd &> /dev/null; then
        log_success "命令 '$cmd' 已安装"
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
    else
        log_warning "命令 '$cmd' 未安装（可选）"
        CHECKS_WARNING=$((CHECKS_WARNING + 1))
    fi
done

# 输出检查结果汇总
echo ""
echo "========================================"
echo "   环境检查结果汇总"
echo "========================================"
echo -e "${GREEN}通过: $CHECKS_PASSED${NC}"
echo -e "${YELLOW}警告: $CHECKS_WARNING${NC}"
echo -e "${RED}失败: $CHECKS_FAILED${NC}"
echo ""

# 根据检查结果给出建议
if [ $CHECKS_FAILED -eq 0 ]; then
    log_success "环境检查全部通过！可以继续安装 Jimi"
    echo ""
    echo "下一步："
    echo "  1. 运行 ./scripts/install-deps.sh 安装依赖"
    echo "  2. 运行 ./scripts/build.sh 构建项目"
    echo "  3. 运行 ./scripts/init-config.sh 初始化配置"
    echo "  4. 运行 ./scripts/start.sh 启动 Jimi"
    echo ""
    echo "或者直接运行一键安装脚本："
    echo "  ./scripts/quick-install.sh"
    exit 0
else
    log_error "环境检查未通过，请解决以下问题："
    echo ""
    if ! command -v java &> /dev/null || [ "$JAVA_VERSION" -lt 17 ]; then
        echo "  - 安装 Java 17 或更高版本"
        if [[ "$OS_TYPE" == "Darwin"* ]]; then
            echo "    macOS: brew install openjdk@17"
        else
            echo "    Linux: sudo apt install openjdk-17-jdk (Ubuntu/Debian)"
        fi
    fi
    if ! command -v mvn &> /dev/null; then
        echo "  - 安装 Maven"
        if [[ "$OS_TYPE" == "Darwin"* ]]; then
            echo "    macOS: brew install maven"
        else
            echo "    Linux: sudo apt install maven (Ubuntu/Debian)"
        fi
    fi
    exit 1
fi
