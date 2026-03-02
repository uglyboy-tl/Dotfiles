---
description: 将当前功能分支合并到开发分支并集成到主干
agent: build
---

按以下步骤执行合并流程：

1. **验证环境并获取信息**：
   - 并行执行：`git status --porcelain`、`git rev-parse --abbrev-ref HEAD`、`git worktree list`、`pwd`
   - 验证不在主分支（main/master/develop）且当前目录在主仓库的 `.worktrees/` 子目录下，否则停止
   - 若工作区有未提交更改，立即调用内置命令 `/commit` 提交（该命令会自动调用 git-commiter subagent 执行）

2. **切换到 develop 分支并同步**：
   - 检查 develop 工作区是否存在（从 `git worktree list` 结果中查找）
   - 不存在则切换到主仓库目录（从 `git worktree list` 第一行获取）并使用 `using-git-worktrees` 技能创建：
     - 本地 develop 不存在时：从远程 checkout 或从主干创建
   - 切换到 develop worktree
   - 如果 develop 分支跟踪远程，则执行 `git pull origin develop`

3. **合并功能分支**：
   - 执行 `git merge <功能分支名>`（使用步骤1获取的当前分支名）
   - **冲突检测**：如果合并失败或有冲突，向用户说明情况并提供解决建议

4. **运行集成测试**：
   - 根据 AGENTS.md 中的项目指导确定测试方式
   - 如果项目是代码开发项目且分支功能与代码相关，则执行完整测试套件
   - 如果项目非代码开发或分支功能与代码无关，跳过测试步骤
   - **失败处理**：测试失败则向用户说明情况并提供回滚选项

5. **清理功能分支**：
   - 删除本地功能分支：`git branch -d <功能分支名>`
   - 删除对应 worktree 目录 `git worktree remove <功能分支目录>`

6. **完成状态报告**：
   - 成功完成前5步后，向用户报告成功状态和分支信息
   - 询问用户："是否将 develop 分支合并到主干并打标签？"
   - 若用户确认，继续执行：
     - 切换到主干分支（main/master）
     - 合并 develop 分支
     - 创建版本标签（基于语义化版本）
     - 推送主干和标签到远程