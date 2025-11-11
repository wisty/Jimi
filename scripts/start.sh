#!/bin/bash
#############################################################################
# Jimi 启动脚本
# 用途：启动 Jimi 应用程序
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

echo "========================================"
echo "   Jimi 启动工具"
echo "========================================"
echo ""

# 获取项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="$PROJECT_DIR/target"
CONFIG_DIR="$HOME/.jimi"

# 查找 JAR 文件
find_jar() {
    # 优先使用符号链接
    if [ -f "$PROJECT_DIR/jimi.jar" ]; then
        echo "$PROJECT_DIR/jimi.jar"
        return
    fi
    
    # 在 target 目录查找
    local jar_file=$(find "$TARGET_DIR" -name "jimi-*.jar" -not -name "*-sources.jar" 2>/dev/null | head -n 1)
    if [ -n "$jar_file" ]; then
        echo "$jar_file"
        return
    fi
    
    echo ""
}

JAR_FILE=$(find_jar)

if [ -z "$JAR_FILE" ]; then
    log_error "未找到 Jimi JAR 文件"
    log_info "请先运行构建脚本: ./scripts/build.sh"
    exit 1
fi

log_success "找到 JAR 文件: $(basename "$JAR_FILE")"

# 检查 Java
if ! command -v java &> /dev/null; then
    log_error "未找到 Java，请先安装 Java 17 或更高版本"
    exit 1
fi

JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
if [ "$JAVA_VERSION" -lt 17 ]; then
    log_error "Java 版本过低，需要 Java 17+，当前版本: $JAVA_VERSION"
    exit 1
fi

log_success "Java 版本: $JAVA_VERSION"

# 检查配置文件
CONFIG_FILE="$CONFIG_DIR/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    log_warning "未找到配置文件: $CONFIG_FILE"
    read -p "是否现在初始化配置？[y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        "$SCRIPT_DIR/init-config.sh"
    else
        log_info "提示：可以运行 ./scripts/init-config.sh 初始化配置"
    fi
fi

# 解析命令行参数
JVM_OPTS=""
APP_ARGS=""
WORK_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -Xmx*|-Xms*|-XX:*)
            # JVM 参数
            JVM_OPTS="$JVM_OPTS $1"
            shift
            ;;
        --work-dir)
            WORK_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "用法: $0 [JVM选项] [应用参数]"
            echo ""
            echo "JVM 选项:"
            echo "  -Xmx<size>          设置最大堆内存，如: -Xmx2g"
            echo "  -Xms<size>          设置初始堆内存，如: -Xms512m"
            echo "  -XX:+<option>       启用 JVM 选项"
            echo ""
            echo "应用参数:"
            echo "  --work-dir <dir>    指定工作目录"
            echo "  --help              显示此帮助信息"
            echo ""
            echo "示例:"
            echo "  $0 -Xmx2g"
            echo "  $0 --work-dir /path/to/project"
            echo ""
            exit 0
            ;;
        *)
            # 其他参数传递给应用程序
            APP_ARGS="$APP_ARGS $1"
            shift
            ;;
    esac
done

# 设置默认 JVM 参数
if [ -z "$JVM_OPTS" ]; then
    JVM_OPTS="-Xmx1g -Xms512m"
    log_info "使用默认 JVM 参数: $JVM_OPTS"
fi

# 设置工作目录
if [ -n "$WORK_DIR" ]; then
    if [ ! -d "$WORK_DIR" ]; then
        log_error "工作目录不存在: $WORK_DIR"
        exit 1
    fi
    cd "$WORK_DIR"
    log_info "工作目录: $WORK_DIR"
else
    log_info "工作目录: $(pwd)"
fi

# 显示启动信息
echo ""
echo "========================================"
echo "   启动配置"
echo "========================================"
echo "JAR 文件: $(basename "$JAR_FILE")"
echo "JVM 参数: $JVM_OPTS"
if [ -n "$APP_ARGS" ]; then
    echo "应用参数: $APP_ARGS"
fi
echo "配置目录: $CONFIG_DIR"
echo "========================================"
echo ""

# 启动应用
log_info "正在启动 Jimi..."
echo ""

# 构建启动命令
JAVA_CMD="java $JVM_OPTS -jar \"$JAR_FILE\" $APP_ARGS"

# 执行启动
eval $JAVA_CMD

# 如果程序正常退出
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    log_success "Jimi 正常退出"
else
    log_error "Jimi 退出，退出码: $EXIT_CODE"
    exit $EXIT_CODE
fi
