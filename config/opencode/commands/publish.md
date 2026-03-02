---
description: 将 develop 分支的内容合并到主干分支并清理相关功能分支
agent: worker
---

按以下步骤执行发布流程：

1. **并行收集信息、同步分支并进行验证**：
   ```bash
   # 同步分支
   git pull
   git fetch origin develop:develop

   # 验证环境：检查是否在主仓库目录、主干分支无修改、develop分支存在
   git worktree list  # 第一行为主仓库路径，用于验证当前目录
   pwd                # 当前目录
   git status --porcelain  # 主干分支应无未提交修改
   git branch -a      # 检查 develop 分支是否存在（本地或远程）

   # 收集信息：用于后续步骤
   git log --oneline HEAD..develop  # develop 相比主干的提交，用于版本分析和确认发布内容
   git tag -l          # 现有标签，用于确定最新版本号
   git branch --merged develop  # 已合并到 develop 的分支，用于最后一步清理（需过滤掉主干和 develop 分支）
   ```

   验证条件：
   - 当前在主仓库目录（主干分支）
   - 主干分支没有未提交的修改
   - develop分支存在（本地或远程）
   - 有可发布的提交（如无，询问用户是否继续）

2. **合并 develop 到主干**：
   - 执行 `git merge --no-ff develop`
   - 冲突检测：如果合并失败或有冲突，向用户说明情况并提供解决建议

3. **变基 develop 分支到主干**：
   - 使用子代理在 develop worktree 中执行 `git rebase <主干分支名>`

4. **确定版本标签**：
   - 基于第一步收集的提交列表和标签列表，自动递增语义版本号（修复→修订号，新增功能→次版本号，重大变更→主版本号）
   - 执行 `git tag <新版本标签>`

4. **推送更改**：
   - 推送主干分支：`git push origin HEAD`
   - 推送标签：`git push origin <标签名>`

5. **清理已合并功能分支**：
   - 使用第一步收集的已合并分支列表，过滤掉主干和 develop 分支
   - 对每个功能分支：删除本地 worktree 目录和对应分支（从第一步的 worktree 列表匹配）
   - 推送 develop 分支的清理：`git push origin develop --prune`

注意事项：
- 环境验证（主仓库目录、主干无修改、develop存在）已在第一步完成
- 版本标签自动递增（修复→修订号，新增功能→次版本号，重大变更→主版本号）
- 清理功能分支前建议向用户确认，避免误删
- 任何停止操作都需要向用户明确说明原因