# Jimi 安装与部署脚本

本目录包含用于快速安装和部署 Jimi 系统的自动化脚本。

## 📋 脚本列表

### 🚀 一键安装（推荐）

**`quick-install.sh`** - 一键完成所有安装步骤
```bash
./scripts/quick-install.sh
```

自动执行：环境检查 → 依赖安装 → 项目构建 → 配置初始化 → 启动服务

---

### 🔧 独立脚本

#### 1. **环境检查**

**`check-env.sh`** - 检查系统环境是否满足运行要求
```bash
./scripts/check-env.sh
```

检查内容：
- 操作系统类型
- Java 版本（需要 Java 17+）
- Maven 版本
- Git 工具
- 磁盘空间和内存
- 网络连接

#### 2. **依赖安装**

**`install-deps.sh`** - 自动安装必要的依赖
```bash
./scripts/install-deps.sh
```

支持的系统：
- macOS (使用 Homebrew)
- Ubuntu/Debian (使用 APT)
- CentOS/RHEL (使用 YUM/DNF)

安装内容：
- Java 17 (OpenJDK)
- Maven 3.6+
- Git
- 其他实用工具

#### 3. **配置初始化**

**`init-config.sh`** - 交互式配置向导
```bash
./scripts/init-config.sh
```

配置内容：
- LLM 服务提供商（OpenAI、Moonshot 等）
- API Key 和 Base URL
- 模型选择
- 循环控制参数
- Skills 功能开关

配置文件位置：`~/.jimi/config.json`

#### 4. **项目构建**

**`build.sh`** - 编译并打包项目
```bash
./scripts/build.sh [选项]
```

选项：
- `-s, --skip-tests` - 跳过测试
- `-c, --clean` - 清理后重新构建
- `-p, --profile` - 指定构建配置
- `-h, --help` - 显示帮助

示例：
```bash
# 跳过测试快速构建
./scripts/build.sh --skip-tests

# 清理后完整构建
./scripts/build.sh --clean
```

#### 5. **启动服务**

**`start.sh`** - 启动 Jimi 应用
```bash
./scripts/start.sh [JVM选项] [应用参数]
```

JVM 选项：
- `-Xmx<size>` - 设置最大堆内存，如：`-Xmx2g`
- `-Xms<size>` - 设置初始堆内存，如：`-Xms512m`

应用参数：
- `--work-dir <dir>` - 指定工作目录

示例：
```bash
# 使用默认配置启动
./scripts/start.sh

# 设置更大的内存启动
./scripts/start.sh -Xmx2g

# 指定工作目录
./scripts/start.sh --work-dir /path/to/project
```

---

## 📦 快速开始

### 新用户安装（3 分钟）

```bash
# 1. 克隆或下载项目
cd /path/to/Jimi

# 2. 运行一键安装脚本
./scripts/quick-install.sh

# 按照提示完成配置即可
```

### 分步安装

```bash
# 1. 检查环境
./scripts/check-env.sh

# 2. 安装依赖（如果需要）
./scripts/install-deps.sh

# 3. 构建项目
./scripts/build.sh --skip-tests

# 4. 初始化配置
./scripts/init-config.sh

# 5. 启动 Jimi
./scripts/start.sh
```

---

## ⚙️ 配置文件说明

配置文件位于：`~/.jimi/config.json`

示例配置：
```json
{
  "llm": {
    "providers": {
      "moonshot": {
        "apiKey": "your-api-key",
        "baseUrl": "https://api.moonshot.cn/v1"
      }
    },
    "defaultProvider": "moonshot",
    "defaultModel": "moonshot-v1-8k"
  },
  "loopControl": {
    "maxSteps": 50,
    "maxRuntime": 3600
  },
  "features": {
    "enableSkills": false,
    "enableApproval": false,
    "enableYoloMode": false
  }
}
```

---

## 🔍 故障排除

### Java 版本问题

**问题**：Java 版本低于 17
```bash
# macOS
export JAVA_HOME=$(/usr/libexec/java_home -v 17)

# Linux
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

将上述命令添加到 `~/.zshrc` 或 `~/.bash_profile`

### 构建失败

**问题**：Maven 构建失败
```bash
# 清理后重试
./scripts/build.sh --clean

# 检查网络连接（Maven 需要下载依赖）
ping repo.maven.apache.org
```

### 配置问题

**问题**：API Key 无效
```bash
# 重新运行配置向导
./scripts/init-config.sh

# 或手动编辑配置文件
vim ~/.jimi/config.json
```

---

## 📁 目录结构

安装后的目录结构：

```
~/.jimi/                    # 用户配置目录
├── config.json             # 主配置文件
├── sessions/               # 会话存储
└── logs/                   # 日志文件

/path/to/Jimi/              # 项目目录
├── scripts/                # 脚本目录
│   ├── check-env.sh
│   ├── install-deps.sh
│   ├── init-config.sh
│   ├── build.sh
│   ├── start.sh
│   └── quick-install.sh
├── target/                 # 构建输出
│   └── jimi-0.1.0.jar
└── jimi.jar               # 符号链接
```

---

## 🛠️ 高级用法

### 添加 Shell 别名

将以下内容添加到 `~/.zshrc` 或 `~/.bash_profile`：

```bash
# Jimi 别名
alias jimi='/path/to/Jimi/scripts/start.sh'
alias jimi-build='/path/to/Jimi/scripts/build.sh'
alias jimi-config='/path/to/Jimi/scripts/init-config.sh'
```

重新加载配置：
```bash
source ~/.zshrc
```

之后可以直接使用：
```bash
jimi              # 启动 Jimi
jimi-build        # 构建项目
jimi-config       # 重新配置
```

### 自定义 JVM 参数

创建启动脚本 `~/.jimi/start-custom.sh`：
```bash
#!/bin/bash
/path/to/Jimi/scripts/start.sh \
  -Xmx2g \
  -Xms512m \
  -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=200
```

### 多环境配置

为不同环境创建配置：
```bash
# 开发环境
cp ~/.jimi/config.json ~/.jimi/config.dev.json

# 生产环境
cp ~/.jimi/config.json ~/.jimi/config.prod.json

# 使用不同配置启动（需修改应用支持）
JIMI_CONFIG=~/.jimi/config.dev.json ./scripts/start.sh
```

---

## 📞 支持

如有问题，请：
1. 查看日志：`~/.jimi/logs/`
2. 运行环境检查：`./scripts/check-env.sh`
3. 查看项目文档
4. 提交 Issue

---

## 📝 版本历史

- **v1.0** - 初始版本
  - 环境检查脚本
  - 依赖安装脚本
  - 配置初始化脚本
  - 构建和启动脚本
  - 一键安装脚本

---

**Happy Coding with Jimi! 🎉**
