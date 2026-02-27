---
description: 提交当前修改
agent: git-commiter
model: deepseek/deepseek-chat
subtask: true
---
$ARGUMENTS

## GIT 状态
### GIT STATUS --short
!`git status --short`

### GIT DIFF --cached
!`git diff --cached`


## 处理流程
### 1. 准备阶段
根据 git status 输出：
- **混合**（已暂存+未暂存）：执行 `git stash push --keep-index -m "temp" && git reset HEAD`
  - 作用：stash 未暂存更改，取消已暂存内容，以便按功能重新分组
- **仅已暂存**：执行 `git reset HEAD`（取消暂存，重新分组）
- **仅未暂存**：跳过

### 2. 原子分组提交
分析文件变更，按功能模块分组，每组执行：
1. `git add <相关文件>`
2. Review（检查原子性、正确性）
3. `git commit -m "type: description"`（遵循 Conventional Commits）

### 3. 恢复阶段
- 混合状态：执行 `git stash pop`
- 其他：跳过

