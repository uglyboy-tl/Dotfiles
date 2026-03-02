---
description: 提交当前修改
agent: git-commiter
model: deepseek/deepseek-chat
subtask: true
---
执行用户指令: $ARGUMENTS

## 处理流程
### 0. 并行上下文收集
并行（按需）执行以下命令，以最小化延迟
```bash
# Group 1: Current state
git status
git diff --staged --stat
git diff --stat

# Group 2: History context
git log -10 --oneline
git log -10 --pretty=format:"%s"
```
一次性获取如下信息：
1. 哪些文件发生了改变
2. 最近10次提交的语言和风格

### 1. 准备阶段
#### 判断需要提交的内容
根据 git status 输出：
- **混合**（已暂存+未暂存）：执行 `git stash push --keep-index -m "temp" && git reset HEAD`
  - 作用：stash 未暂存更改，取消已暂存内容，以便按功能重新分组
- **仅已暂存**：执行 `git reset HEAD`（取消暂存，重新分组）
- **仅未暂存**：跳过

**为何关键：**确保仅提交已完成的变更，避免混入未完成的修改

### 2. 原子分组提交
分析文件变更，按功能模块分组，每组执行：
1. `git add <相关文件>`
2. Review（检查原子性、正确性）
3. `git commit -m "type: description"`（遵循 Conventional Commits）

### 3. 恢复阶段
- 混合状态：执行 `git stash pop`
- 其他：跳过

