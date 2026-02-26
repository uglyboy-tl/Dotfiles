---
description: 提交当前修改
agent: git-commiter
model: deepseek/deepseek-chat
subtask: true
---
$ARGUMENTS

## 当前状态
!`git status`

## 处理流程

### 1. 准备阶段
根据 `git status` 状态：
- **混合**（已暂存+未暂存）：`git stash push -m "temp"`
- **仅已暂存**：`git reset HEAD`  
- **仅未暂存**：跳过

### 2. 原子分组提交
按功能分组，每组执行：`git add` → review → `git commit`（Conventional Commits）

### 3. 恢复阶段
混合状态：`git stash pop`

### 提交前 review
- 原子性、文件范围、内容正确