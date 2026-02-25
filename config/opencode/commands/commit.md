---
description: 提交当前修改
agent: git-commiter
model: deepseek/deepseek-chat
subtask: true
---
$ARGUMENTS

## 当前状态
!`git status`

## 处理逻辑
- 根据上方状态决定提交范围
   - 有暂存文件：只提交暂存内容
   - 无暂存文件：提交所有修改
- 遵循原子提交原则和 Conventional Commits 格式