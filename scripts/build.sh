#!/bin/bash
#############################################################################
# Jimi 项目构建脚本
# 用途：编译并打包 Jimi 项目
# 作者：Jimi Team
#############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

echo "========================================"
echo "   Jimi 项目构建工具"
echo "========================================"
echo ""

# 获取项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="$PROJECT_DIR/target"

log_info "项目目录: $PROJECT_DIR"

# 进入项目目录
cd "$PROJECT_DIR"

# 检查 Maven
if ! command -v mvn &> /dev/null; then
    log_error "未找到 Maven，请先运行 ./scripts/install-deps.sh 安装依赖"
    exit 1
fi

# 检查 Java
if ! command -v java &> /dev/null; then
    log_error "未找到 Java，请先运行 ./scripts/install-deps.sh 安装依赖"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
if [ "$JAVA_VERSION" -lt 17 ]; then
    log_error "Java 版本过低 (需要 17+)，当前版本: $JAVA_VERSION"
    log_info "请设置 JAVA_HOME 环境变量指向 Java 17"
    log_info "例如: export JAVA_HOME=\$(/usr/libexec/java_home -v 17)"
    exit 1
fi

log_success "环境检查通过"
echo ""

# 解析命令行参数
SKIP_TESTS=false
CLEAN_BUILD=false
BUILD_PROFILE="default"

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -p|--profile)
            BUILD_PROFILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  -s, --skip-tests    跳过测试"
            echo "  -c, --clean         清理后重新构建"
            echo "  -p, --profile       指定构建配置文件"
            echo "  -h, --help          显示帮助信息"
            echo ""
            exit 0
            ;;
        *)
            log_error "未知选项: $1"
            echo "使用 -h 或 --help 查看帮助信息"
            exit 1
            ;;
    esac
done

# 构建 Maven 命令
MVN_CMD="mvn"
MVN_GOALS=""

# 是否清理
if [ "$CLEAN_BUILD" = true ]; then
    MVN_GOALS="clean"
    log_info "将执行清理构建"
fi

# 添加 package 目标
MVN_GOALS="$MVN_GOALS package"

# 是否跳过测试
if [ "$SKIP_TESTS" = true ]; then
    MVN_CMD="$MVN_CMD -DskipTests"
    log_info "将跳过测试"
fi

# 显示构建信息
echo "========================================"
echo "   构建配置"
echo "========================================"
echo "清理构建: $CLEAN_BUILD"
echo "跳过测试: $SKIP_TESTS"
echo "构建配置: $BUILD_PROFILE"
echo "========================================"
echo ""

# 记录开始时间
START_TIME=$(date +%s)

# 执行构建
log_info "开始构建..."
echo ""

if $MVN_CMD $MVN_GOALS; then
    # 记录结束时间
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    echo ""
    log_success "构建成功！"
    log_info "耗时: ${DURATION}s"
    
    # 检查生成的 JAR 文件
    JAR_FILE=$(find "$TARGET_DIR" -name "jimi-*.jar" -not -name "*-sources.jar" | head -n 1)
    
    if [ -n "$JAR_FILE" ]; then
        JAR_SIZE=$(ls -lh "$JAR_FILE" | awk '{print $5}')
        echo ""
        echo "========================================"
        echo "   构建产物"
        echo "========================================"
        echo "文件: $(basename "$JAR_FILE")"
        echo "路径: $JAR_FILE"
        echo "大小: $JAR_SIZE"
        echo "========================================"
        echo ""
        
        # 创建符号链接
        LINK_PATH="$PROJECT_DIR/jimi.jar"
        ln -sf "$JAR_FILE" "$LINK_PATH"
        log_success "已创建符号链接: $LINK_PATH"
        
        # 测试 JAR 文件
        log_info "测试 JAR 文件..."
        if java -jar "$JAR_FILE" --version &> /dev/null; then
            log_success "JAR 文件测试通过"
        else
            log_warning "JAR 文件测试失败，但构建成功"
        fi
        
        echo ""
        log_info "下一步："
        echo "  1. 初始化配置: ./scripts/init-config.sh"
        echo "  2. 启动 Jimi: ./scripts/start.sh"
        echo ""
        echo "或直接运行:"
        echo "  java -jar $JAR_FILE"
        echo ""
    else
        log_warning "未找到生成的 JAR 文件"
    fi
else
    # 记录结束时间
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    echo ""
    log_error "构建失败！"
    log_info "耗时: ${DURATION}s"
    echo ""
    log_info "故障排除建议："
    echo "  1. 检查网络连接（Maven 需要下载依赖）"
    echo "  2. 清理并重试: $0 --clean"
    echo "  3. 检查 Java 版本: java -version"
    echo "  4. 查看完整错误日志"
    echo ""
    exit 1
fi
