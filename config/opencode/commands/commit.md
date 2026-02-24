---
description: 提交当前修改
agent: git-commit
model: openrouter/stepfun/step-3.5-flash:free
---
使用 git-commit agent 提交 git 更改。

1. 检查暂存状态：运行 `git status`
2. 处理逻辑：
   - 有暂存文件：只提交暂存内容
   - 无暂存文件：提交所有修改

git-commit agent 将遵循原子提交原则和 Conventional Commits 格式创建提交。