#!/bin/bash
#############################################################################
# Jimi 依赖安装脚本
# 用途：安装 Jimi 运行所需的依赖
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
echo "   Jimi 依赖安装工具"
echo "========================================"
echo ""

# 获取操作系统类型
OS_TYPE=$(uname -s)
log_info "检测到操作系统: $OS_TYPE"

# 检测包管理器
detect_package_manager() {
    if [[ "$OS_TYPE" == "Darwin"* ]]; then
        if command -v brew &> /dev/null; then
            echo "brew"
        else
            echo "none"
        fi
    elif [[ "$OS_TYPE" == "Linux"* ]]; then
        if command -v apt-get &> /dev/null; then
            echo "apt"
        elif command -v yum &> /dev/null; then
            echo "yum"
        elif command -v dnf &> /dev/null; then
            echo "dnf"
        else
            echo "none"
        fi
    else
        echo "none"
    fi
}

PKG_MANAGER=$(detect_package_manager)
log_info "包管理器: $PKG_MANAGER"

# 安装 Java 17
install_java() {
    log_info "开始安装 Java 17..."
    
    case "$PKG_MANAGER" in
        brew)
            log_info "使用 Homebrew 安装 OpenJDK 17..."
            brew install openjdk@17
            
            # 设置符号链接
            if [ -d "/opt/homebrew/opt/openjdk@17" ]; then
                sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk || true
                log_success "Java 17 安装完成"
                
                # 提示设置环境变量
                log_info "请将以下内容添加到您的 shell 配置文件 (~/.zshrc 或 ~/.bash_profile):"
                echo ""
                echo "export JAVA_HOME=\$(/usr/libexec/java_home -v 17)"
                echo "export PATH=\$JAVA_HOME/bin:\$PATH"
                echo ""
            fi
            ;;
        apt)
            log_info "使用 APT 安装 OpenJDK 17..."
            sudo apt-get update
            sudo apt-get install -y openjdk-17-jdk
            log_success "Java 17 安装完成"
            ;;
        yum|dnf)
            log_info "使用 $PKG_MANAGER 安装 OpenJDK 17..."
            sudo $PKG_MANAGER install -y java-17-openjdk-devel
            log_success "Java 17 安装完成"
            ;;
        none)
            log_error "无法自动安装 Java，请手动安装 Java 17"
            log_info "访问 https://adoptium.net/ 下载 Java 17"
            return 1
            ;;
    esac
}

# 安装 Maven
install_maven() {
    log_info "开始安装 Maven..."
    
    case "$PKG_MANAGER" in
        brew)
            log_info "使用 Homebrew 安装 Maven..."
            brew install maven
            log_success "Maven 安装完成"
            ;;
        apt)
            log_info "使用 APT 安装 Maven..."
            sudo apt-get update
            sudo apt-get install -y maven
            log_success "Maven 安装完成"
            ;;
        yum|dnf)
            log_info "使用 $PKG_MANAGER 安装 Maven..."
            sudo $PKG_MANAGER install -y maven
            log_success "Maven 安装完成"
            ;;
        none)
            log_warning "无法使用包管理器安装 Maven，尝试手动安装..."
            install_maven_manually
            ;;
    esac
}

# 手动安装 Maven
install_maven_manually() {
    MAVEN_VERSION="3.9.6"
    MAVEN_HOME="/opt/maven"
    
    log_info "下载 Maven $MAVEN_VERSION..."
    curl -fsSL "https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz" -o /tmp/maven.tar.gz
    
    log_info "解压 Maven..."
    sudo mkdir -p $MAVEN_HOME
    sudo tar -xzf /tmp/maven.tar.gz -C $MAVEN_HOME --strip-components=1
    rm /tmp/maven.tar.gz
    
    log_success "Maven 安装完成"
    log_info "请将以下内容添加到您的 shell 配置文件:"
    echo ""
    echo "export MAVEN_HOME=$MAVEN_HOME"
    echo "export PATH=\$MAVEN_HOME/bin:\$PATH"
    echo ""
}

# 安装 Git
install_git() {
    log_info "开始安装 Git..."
    
    case "$PKG_MANAGER" in
        brew)
            log_info "使用 Homebrew 安装 Git..."
            brew install git
            log_success "Git 安装完成"
            ;;
        apt)
            log_info "使用 APT 安装 Git..."
            sudo apt-get update
            sudo apt-get install -y git
            log_success "Git 安装完成"
            ;;
        yum|dnf)
            log_info "使用 $PKG_MANAGER 安装 Git..."
            sudo $PKG_MANAGER install -y git
            log_success "Git 安装完成"
            ;;
        none)
            log_error "无法自动安装 Git，请手动安装"
            return 1
            ;;
    esac
}

# 安装其他实用工具
install_utilities() {
    log_info "安装其他实用工具..."
    
    case "$PKG_MANAGER" in
        brew)
            brew install curl wget unzip || true
            ;;
        apt)
            sudo apt-get install -y curl wget unzip || true
            ;;
        yum|dnf)
            sudo $PKG_MANAGER install -y curl wget unzip || true
            ;;
    esac
    
    log_success "实用工具安装完成"
}

# 主安装流程
main() {
    # 检查 Java
    if ! command -v java &> /dev/null; then
        log_warning "未检测到 Java，开始安装..."
        install_java
    else
        JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
        if [ "$JAVA_VERSION" -lt 17 ]; then
            log_warning "Java 版本过低 (需要 17+)，开始升级..."
            install_java
        else
            log_success "Java 已安装且版本满足要求"
        fi
    fi
    
    # 检查 Maven
    if ! command -v mvn &> /dev/null; then
        log_warning "未检测到 Maven，开始安装..."
        install_maven
    else
        log_success "Maven 已安装"
    fi
    
    # 检查 Git
    if ! command -v git &> /dev/null; then
        log_warning "未检测到 Git，开始安装..."
        install_git
    else
        log_success "Git 已安装"
    fi
    
    # 安装其他工具
    install_utilities
    
    echo ""
    echo "========================================"
    echo "   依赖安装完成"
    echo "========================================"
    echo ""
    log_success "所有依赖已安装完成！"
    echo ""
    log_info "下一步："
    echo "  1. 重新加载 shell 配置: source ~/.zshrc (或 ~/.bash_profile)"
    echo "  2. 验证安装: ./scripts/check-env.sh"
    echo "  3. 构建项目: ./scripts/build.sh"
    echo ""
}

# 执行主流程
main
