---
name: using-git-worktrees
description: 在开始需要与当前工作区隔离的功能开发或执行实施计划前使用——创建具有智能目录选择和安全验证的隔离式 Git 工作区
---

# 使用 Git 工作区（Worktrees）

## 概述

Git 工作区可创建共享同一仓库的隔离工作空间，允许同时在多个分支上工作而无需切换。

**核心原则：** 系统化的目录选择 + 安全验证 = 可靠的隔离。

**开始时声明：** "我正在使用 using-git-worktrees 技能设置隔离工作区。"

## 目录选择流程

按以下优先级顺序操作：

### 1. 检查现有目录

```bash
# 按优先级顺序检查
ls -d .worktrees 2>/dev/null     # 首选（隐藏）
ls -d worktrees 2>/dev/null      # 备选
```

**如果找到：** 使用该目录。如果两者都存在，优先使用 `.worktrees`。

### 2. 检查 AGENTS.md

```bash
grep -i "worktree.*director" AGENTS.md 2>/dev/null
```

**如果指定了偏好：** 直接使用，无需询问。

### 3. 询问用户

如果不存在目录且 AGENTS.md 中无偏好设置：

```
未找到工作区目录。应在何处创建工作区？

1. .worktrees/（项目本地，隐藏）
2. ~/.config/worktrees/<项目名>/（全局位置）

您更倾向哪种？
```

## 安全验证

### 对于项目本地目录（.worktrees 或 worktrees）

**创建工作区前必须验证目录是否被忽略：**

```bash
# 检查目录是否被忽略（遵循本地、全局和系统 gitignore）
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**如果未被忽略：**

根据 Jesse 的规则"立即修复损坏事项"：
1. 在 .gitignore 中添加相应行
2. 提交更改
3. 继续创建工作区

**为何关键：** 防止意外将工作区内容提交到仓库中。

### 对于全局目录（~/.config/worktrees）

无需 .gitignore 验证 —— 完全位于项目外部。

## 创建步骤

### 1. 检测项目名称

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
```

### 2. 创建工作区

```bash
# 确定完整路径
case $LOCATION in
  .worktrees|worktrees)
    path="$LOCATION/$BRANCH_NAME"
    ;;
  ~/.config/worktrees/*)
    path="~/.config/worktrees/$project/$BRANCH_NAME"
    ;;
esac

# 创建带新分支的工作区
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

### 3. 运行项目设置

自动检测并运行适当的设置：

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

### 4. 验证干净基线

运行测试确保工作区初始状态干净：

```bash
# 示例 - 使用项目适用的命令
npm test
cargo test
pytest
go test ./...
```

**如果测试失败：** 报告失败，询问是否继续或调查。

**如果测试通过：** 报告就绪。

### 5. 报告位置

```
工作区已准备就绪：<完整路径>
测试通过（<N> 个测试，0 个失败）
已准备好实现 <功能名称>
```

## 快速参考

| 情况 | 操作 |
|------|------|
| `.worktrees/` 存在 | 使用它（验证已忽略） |
| `worktrees/` 存在 | 使用它（验证已忽略） |
| 两者都存在 | 使用 `.worktrees/` |
| 两者都不存在 | 检查 CLAUDE.md → 询问用户 |
| 目录未被忽略 | 添加到 .gitignore + 提交 |
| 基线测试失败 | 报告失败 + 询问 |
| 无 package.json/Cargo.toml | 跳过依赖安装 |

## 常见错误

### 跳过忽略验证

- **问题：** 工作区内容被跟踪，污染 git 状态
- **修复：** 创建项目本地工作区前始终使用 `git check-ignore`

### 假设目录位置

- **问题：** 导致不一致，违反项目约定
- **修复：** 遵循优先级：现有 > CLAUDE.md > 询问

### 在测试失败时继续

- **问题：** 无法区分新 bug 与已有问题
- **修复：** 报告失败，获得明确许可后再继续

### 硬编码设置命令

- **问题：** 在使用不同工具的项目上会失败
- **修复：** 从项目文件自动检测（package.json 等）

## 示例工作流

```
你：我正在使用 using-git-worktrees 技能设置隔离工作区。

[检查 .worktrees/ - 存在]
[验证已忽略 - git check-ignore 确认 .worktrees/ 已被忽略]
[创建工作区：git worktree add .worktrees/auth -b feature/auth]
[运行 npm install]
[运行 npm test - 47 个通过]

工作区已准备就绪：/Users/jesse/myproject/.worktrees/auth
测试通过（47 个测试，0 个失败）
已准备好实现认证功能
```

## 红旗警告

**绝不：**
- 未经验证忽略状态就创建工作区（项目本地）
- 跳过基线测试验证
- 未经询问就在测试失败时继续
- 在模糊情况下假设目录位置
- 跳过 CLAUDE.md 检查

**始终：**
- 遵循目录优先级：现有 > CLAUDE.md > 询问
- 为项目本地目录验证忽略状态
- 自动检测并运行项目设置
- 验证干净的测试基线

## 集成

**由以下调用：**
- **测试驱动开发（TDD）专家** - 执行任何任务前触发本技能
- **executing-plans** - 执行任何任务前触发本技能
- 任何需要隔离工作区的技能