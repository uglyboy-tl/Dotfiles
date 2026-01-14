# AGENTS.md - Dotfiles 代码库指南

本文档为 AI 代理（如 Sisyphus）提供在此 dotfiles 代码库中工作的指南。本代码库使用 [dotbot](https://github.com/anishathalye/dotbot) 工具管理配置文件。

## 目录
1. [项目概述](#项目概述)
2. [构建和测试命令](#构建和测试命令)
3. [Git 提交管理](#git-提交管理)
4. [代码风格指南](#代码风格指南)
5. [dotbot 配置指南](#dotbot-配置指南)
6. [脚本编写规范](#脚本编写规范)
7. [测试和验证](#测试和验证)
8. [分支管理](#分支管理)
9. [常见任务](#常见任务)
10. [dotbot 最佳实践](#dotbot-最佳实践)
11. [注意事项](#注意事项)

## 项目概述

这是一个使用 dotbot 管理的多分支 dotfiles 项目，支持服务器端和桌面端配置。项目采用分支架构管理不同环境的配置：

### 分支架构
- **main**: 服务器端基础配置（核心配置）
- **PC**: 桌面端扩展配置（基于 main 分支的补充和扩展）
- **laptop**: 笔记本电脑特定配置（可选分支）

### 设计理念
1. **基础与扩展**: `main` 分支包含服务器端通用配置，`PC` 分支在此基础上添加桌面环境特定配置
2. **配置继承**: 桌面端配置继承并扩展服务器端配置，避免重复
3. **环境隔离**: 不同环境的配置通过分支隔离，便于管理和部署

### 主要组件
- **dotbot**: 子模块，用于自动化配置文件的安装和链接
- **config/**: 各种应用程序的配置文件
- **scripts/**: 自定义脚本文件
- **applications/**: 桌面应用程序配置文件
- **data/**: 数据文件（如动态壁纸）

## 构建和测试命令

### 主要安装命令
```bash
# 完整安装（使用默认配置）
./install

# 安装特定配置
./install -c install.conf.yaml

# 仅执行链接操作
./install --only link

# 排除特定操作
./install --except shell

# 干运行模式（预览更改）
./install --dry-run

# 启用详细输出
./install --verbose
```

### dotbot 子模块管理
```bash
# 更新 dotbot 子模块
git submodule update --init --recursive dotbot

# 同步子模块
git -C dotbot submodule sync --quiet --recursive

# 更新所有子模块
git submodule foreach git pull
```

### dotbot 开发命令（在 dotbot/ 目录中）
```bash
# 运行测试
hatch test

# 运行特定测试
hatch test tests/test_link.py
hatch test tests/test_link.py::test_link_creates_symlink

# 类型检查
hatch run types:check

# 代码格式化
hatch fmt

# 仅检查格式（不修改）
hatch fmt --check

# 构建包
hatch build
```

### 项目启动更新流程
每次项目启动时，AI代理应优先检查并更新远端代码和子模块：

```bash
# 1. 检查远端更新
git fetch --all

# 2. 更新当前分支（如果存在上游分支）
git pull --rebase

# 3. 更新所有子模块
git submodule update --init --recursive

# 4. 同步子模块配置
git submodule sync --recursive

# 5. 更新子模块内容
git submodule foreach --recursive git pull origin main

# 完整的启动更新脚本示例
#!/usr/bin/env bash
set -e

echo "🔍 检查远端更新..."
git fetch --all

echo "📥 更新当前分支..."
if git rev-parse --abbrev-ref @{u} >/dev/null 2>&1; then
    git pull --rebase
else
    echo "⚠️  当前分支没有设置上游分支，跳过pull"
fi

echo "🔄 更新子模块..."
git submodule update --init --recursive
git submodule sync --recursive
git submodule foreach --recursive git pull origin main

echo "✅ 项目更新完成"
```

### 测试脚本
```bash
# 运行动态壁纸测试脚本
./data/dynamic-wallpaper/test.sh

# 测试 24-bit 颜色支持
./scripts/24-bit-color.sh

# ShellCheck 检查
shellcheck scripts/*.sh

# 语法检查
bash -n scripts/*.sh
```

## Git 提交管理

### 提交流程规范
本项目支持自动git提交管理，但每次提交前需要用户确认。AI代理应遵循以下提交流程：

1. **准备阶段**:
   ```bash
   # 查看当前状态
   git status
   
   # 查看具体更改
   git diff
   
   # 查看最近提交记录（了解提交风格）
   git log --oneline -5
   ```

2. **暂存更改**:
   ```bash
   # 添加特定文件
   git add <file1> <file2>
   
   # 添加所有更改
   git add .
   ```

3. **创建提交**:
   ```bash
   # 创建提交（需要用户确认）
   git commit -m "feat(config): 描述更改内容"
   ```

### 提交消息规范
遵循约定式提交（Conventional Commits）规范：

```
<类型>[可选的作用域]: <描述>

[可选的正文]
[可选的脚注]
```

**常用类型**:
- `feat`: 新功能
- `fix`: 错误修复
- `docs`: 文档更新
- `style`: 代码格式调整（不影响功能）
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

**示例**:
```
feat(config): 添加Alacritty终端配置
fix(zsh): 修复环境变量加载问题
docs: 更新AGENTS.md文件
chore: 更新dotbot子模块
```

### 分支管理提交
- **通用配置**: 提交到 `main` 分支
- **桌面特定配置**: 提交到 `PC` 分支
- **跨分支更改**: 先在 `main` 分支提交，然后合并到 `PC` 分支

## 代码风格指南

### 文件编码和换行符
- 使用 UTF-8 编码
- 使用 LF（Unix）换行符
- 文件末尾添加换行符

### Shell 脚本规范
1. **Shebang**: 使用 `#!/usr/bin/env bash` 或 `#!/bin/bash`
2. **错误处理**: 设置 `set -e` 在错误时退出
3. **变量引用**: 使用双引号引用变量：`"$variable"`
4. **函数定义**: 使用 `function_name() { ... }` 格式
5. **注释**: 在复杂逻辑前添加注释，使用英文或中文

### YAML 配置文件规范
1. **缩进**: 使用 2 个空格
2. **键值对**: 冒号后加空格
3. **数组**: 使用连字符 `-` 表示列表项
4. **多行字符串**: 使用 `|` 或 `>` 符号

### Python 代码规范（dotbot 子模块）
- 遵循 PEP 8 规范
- 使用 4 个空格缩进
- 导入顺序：标准库 → 第三方库 → 本地模块
- 类型提示：使用 mypy 进行类型检查

## dotbot 配置指南

### 配置文件结构
`install.conf.yaml` 是主要的 dotbot 配置文件，包含以下部分：

1. **defaults**: 默认配置选项
2. **clean**: 清理旧的符号链接
3. **shell**: 执行 shell 命令
4. **link**: 创建符号链接
5. **插件配置**（如 crontab）

### 链接配置示例
```yaml
- link:
    # 简单链接
    ~/.vimrc: config/vim/vimrc
    
    # 扩展配置
    ~/.local/bin/:
        create: true
        glob: true
        path: scripts/*
        relink: true
    
    # 条件链接
    $XDG_CONFIG_HOME/zsh/.zshrc:
        path: config/zsh/zshrc.zsh
        force: true
```

### 环境变量
dotbot 支持环境变量扩展：
- `~`: 用户家目录
- `$XDG_CONFIG_HOME`: XDG 配置目录（默认 ~/.config）
- `$XDG_DATA_HOME`: XDG 数据目录（默认 ~/.local/share）

## 脚本编写规范

### 脚本位置
- 可执行脚本放在 `scripts/` 目录
- 通过 dotbot 链接到 `~/.local/bin/`

### 脚本要求
1. **可执行权限**: `chmod +x script.sh`
2. **错误处理**: 包含适当的错误检查和退出代码
3. **日志输出**: 提供有意义的输出信息
4. **参数处理**: 支持命令行参数和帮助信息

### 示例脚本结构
```bash
#!/usr/bin/env bash

set -e  # 出错时退出

# 脚本描述
# 用法: script.sh [选项]
# 选项:
#   -h, --help     显示帮助信息
#   -v, --version  显示版本信息

# 函数定义
function show_help() {
    cat << EOF
Usage: $0 [OPTIONS]
Options:
    -h, --help      Show this help message
    -v, --version   Show version information
EOF
}

# 主逻辑
main() {
    # 参数解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 脚本主体逻辑
    echo "Script execution completed"
}

# 执行主函数
main "$@"
```

## 测试和验证

### dotbot 配置验证
```bash
# 验证 YAML 语法
python -c "import yaml; yaml.safe_load(open('install.conf.yaml'))"

# 干运行测试
./install --dry-run
```

### 符号链接验证
```bash
# 检查符号链接
find ~ -maxdepth 1 -type l -name ".*" -ls

# 检查特定链接
ls -la ~/.vimrc
readlink ~/.vimrc
```

### 脚本测试
```bash
# ShellCheck 检查
shellcheck scripts/*.sh

# 语法检查
bash -n scripts/*.sh
```

## 分支管理

### 分支切换和工作流程
```bash
# 查看所有分支
git branch -a

# 切换到服务器端配置（基础配置）
git checkout main

# 切换到桌面端配置（扩展配置）
git checkout PC

# 创建新分支（用于特定环境）
git checkout -b new-environment

# 合并服务器端更新到桌面端
git checkout PC
git merge main
```

### 配置继承策略
1. **服务器端配置 (main)**: 包含通用配置，如：
   - Shell 配置（zsh, bash）
   - 终端工具（vim, git, tmux）
   - 系统工具（ssh, cron）
   - 编程环境（python, node）

2. **桌面端配置 (PC)**: 继承并扩展服务器端配置，添加：
   - 窗口管理器（bspwm, sxhkd）
   - 桌面环境（polybar, rofi, dunst）
   - 多媒体应用（mpv, alacritty）
   - 图形工具（字体, 主题, 壁纸）

3. **配置优先级**: 桌面端配置可以覆盖服务器端配置，但应保持向后兼容

## 常见任务

### 添加新的配置文件
1. **确定配置类型**:
   - 通用配置 → 添加到 `main` 分支
   - 桌面特定配置 → 添加到 `PC` 分支
   - 环境特定配置 → 创建新分支

2. **实施步骤**:
   - 将配置文件添加到 `config/` 目录的相应子目录
   - 在 `install.conf.yaml` 中添加链接配置
   - 测试链接：`./install --dry-run --only link`
   - 应用更改：`./install`

### 跨分支同步配置
```bash
# 1. 在服务器端添加通用配置
git checkout main
# 添加配置并提交

# 2. 将通用配置合并到桌面端
git checkout PC
git merge main
# 解决可能的冲突

# 3. 在桌面端添加特定扩展
# 添加桌面特定配置并提交
```

### 添加新脚本
1. 将脚本添加到 `scripts/` 目录
2. 确保脚本有可执行权限：`chmod +x scripts/new-script.sh`
3. 脚本会自动链接到 `~/.local/bin/`

### 更新 dotbot 子模块
```bash
# 进入 dotbot 目录
cd dotbot

# 拉取最新更改
git pull origin master

# 返回根目录并提交
cd ..
git add dotbot
git commit -m "更新 dotbot 到最新版本"
```

### 调试 dotbot 问题
```bash
# 启用详细输出
./install --verbose

# 仅运行特定部分
./install --only link

# 检查日志文件
cat dotbot.log
```

## dotbot 最佳实践

### 配置设计原则
1. **幂等性**: 配置应该可以安全地多次运行，不会产生副作用
2. **模块化**: 按应用程序组织配置文件，便于维护
3. **条件执行**: 使用 `if:` 选项处理平台特定的配置
4. **环境变量**: 使用 `$XDG_CONFIG_HOME`, `$XDG_DATA_HOME` 等标准环境变量

### 常见配置模式
```yaml
# 默认配置（适用于所有链接）
- defaults:
    link:
      create: true    # 自动创建父目录
      relink: true    # 允许重新链接
      force: false    # 谨慎使用 force

# 清理阶段（先清理再链接）
- clean:
    ~/:
      force: true
    $XDG_CONFIG_HOME:
      recursive: true

# 链接配置（使用 glob 模式批量链接）
- link:
    ~/.local/bin/:
      create: true
      glob: true
      path: scripts/*
      relink: true

# 条件配置（平台特定）
- link:
    ~/.config/alacritty/alacritty.toml:
      path: config/alacritty/alacritty.toml
      if: '[ `uname` = Linux ]'
```

### 错误处理策略
1. **dry-run 优先**: 始终先使用 `--dry-run` 测试配置
2. **逐步应用**: 使用 `--only` 选项分阶段应用配置
3. **日志记录**: 检查 `dotbot.log` 文件了解详细执行过程
4. **回滚计划**: 重要更改前备份现有配置

## 注意事项

### 安全性
1. **不要提交敏感信息**: 避免在配置文件中包含密码、API 密钥等
2. **谨慎使用 force**: 仅在必要时使用 `force: true`
3. **备份重要文件**: 使用 `backup: true` 选项
4. **权限管理**: 注意文件权限，特别是脚本文件

### 兼容性
1. **跨平台支持**: 考虑不同操作系统的兼容性
2. **条件执行**: 使用 `if:` 选项进行条件判断
3. **路径处理**: 注意 Windows 和 Unix 系统的路径差异
4. **环境检测**: 检测 shell 类型、平台特性等

### 维护性
1. **模块化组织**: 按应用程序组织配置文件
2. **文档化**: 在配置文件中添加注释说明
3. **版本控制**: 定期提交更改并添加有意义的提交信息
4. **子模块管理**: 定期更新子模块，保持依赖最新

### 对于 AI 代理的特殊指导
1. **理解上下文**: 这是一个 dotfiles 项目，不是传统的软件项目
2. **分支意识**: 注意当前所在分支（main = 服务器端，PC = 桌面端）
3. **配置继承**: 桌面端配置基于服务器端配置，添加修改时要考虑兼容性
4. **git提交管理**: 支持自动提交但需要用户确认，遵循提交流程规范
5. **提交消息**: 使用约定式提交格式，清晰描述更改内容
6. **谨慎修改**: 对现有配置的修改可能影响用户的系统环境
7. **测试优先**: 始终先使用 `--dry-run` 测试更改
8. **用户意图**: 确保理解用户请求的 dotfiles 管理意图
9. **配置验证**: 修改后验证 YAML 语法和链接正确性
10. **渐进式更改**: 一次只做一个小的更改，验证后再继续
11. **跨分支同步**: 通用配置应添加到 main 分支，然后合并到 PC 分支
12. **项目启动更新**: 每次项目启动时，优先检查并更新远端代码和子模块，确保工作在最新代码基础上

---

*最后更新: 2025-01-14*
*适用于: dotfiles 代码库使用 dotbot 进行管理*