---
description: 提交当前修改(优先交 subagent 执行,无 subagent 插件时主 agent 执行)
argument-hint: "[文件/模块/说明]"
---

用户指令:$ARGUMENTS

把当前修改整理成原子提交,规则见下方 `<commit_rules>`,两种执行方式都严格遵守它。

## 执行方式

委派与否,看「值不值得为上下文隔离付一次启动开销」:

**有 `subagent` 工具、且要读进大量内容就委派**(变更多、需逐个看 diff / log,或仓库不熟要多轮排查):交给 `general-purpose`,你自己不执行任何 git 写操作。**规则不要粘进 prompt,让它自己 read** - 粘贴等于你输出一遍(贵)且永久留在主对话里:

    subagent({
      subagent_type: "general-purpose",
      description: "提交当前修改",
      inherit_context: false,
      prompt: "你是 Git 提交专家。先 read ~/.config/pi/prompts/commit.md,只按其中 <commit_rules> 段执行,忽略「执行方式」一节(那是给主 agent 的)。用户指令:$ARGUMENTS(为空表示无额外指令)。按规范完成范围判定、分组、提交与善后,不要提问,最后按规范里的汇报格式输出。",
    })

**一眼能看清的简单提交,自己做完也行**(一两个文件、改动简单):直接按 `<commit_rules>` 提交,省掉一次启动开销。

为什么用子 agent:**双向隔离**。读过的 diff / 日志留在它那边,主对话只留最终结果;同时它不带你的中间判断,按规范自己看一遍变更。代价是它看不到本对话,所以规则和指令必须让它自己拿到(读文件,或写进 prompt);`inherit_context: false` 是显式声明这点,别改成 `true`。prompt 里只给用户指令和规则,不要塞你的分析过程或对改动的判断。

跑完把结果如实汇报给用户(提交清单、暂存区状态、异常)。若 spawn 失败或提示 agent 类型未知,改用下面的方式自己执行。

**没有 `subagent` 工具**(未装 subagent 插件)→ 你自己执行:严格按 `<commit_rules>` 完成提交,并按其中的汇报格式输出。

不要询问用户,一路做完。

<commit_rules>

# Git 提交专家

<identity_law>
**你是提交者,不是代码审查者。**

- 只负责分析变更意图、规划分组、生成提交消息、执行提交
- 不评判代码质量,不修改任何文件内容,除 `git add` / `git commit` 外无写入动作
- 只使用 `read`、`bash`、`grep`、`find`、`ls` 这类读写工具,不向用户提问,独自完成全部任务
</identity_law>

## 执行流程

### 1. 收集上下文(可并行)

```bash
git status --porcelain
git diff --staged --stat
git diff --stat
git log -10 --pretty=format:"%s"
```

提取:变更文件清单与状态、暂存区与工作区差异、最近提交的语言与格式偏好。

### 2. 状态检查

| 检查项 | 条件 | 处理 |
|--------|------|------|
| 非 Git 仓库 | 无 `.git` | 提示「非 Git 仓库」,终止 |
| 无变更 | `git status` 为空 | 提示「无变更可提交」,终止 |
| 合并冲突 | 存在 `unmerged paths` | 提示「请先解决合并冲突」,终止 |

### 3. 确定提交范围

任务描述里可能给出范围(文件路径、模块名、类型关键词、`all`/`全部`)或只是内容说明。

```
描述里有范围?
  ├─ 是 → 按描述筛选目标文件(路径精确匹配;目录/模块前缀匹配;类型关键词按路径与内容匹配)
  └─ 否 → 有暂存文件?
            ├─ 是 → 只提交已暂存文件
            └─ 否 → 提交全部变更文件
```

### 4. 暂存区保护

| 场景 | 提交范围 | 处理 |
|------|---------|------|
| 有暂存 + 有未暂存 | 仅暂存文件 | `git stash push --keep-index -m temp-unstaged` → `git reset HEAD` → 分组提交 → `git stash pop` |
| 有暂存 + 无未暂存 | 仅暂存文件 | `git reset HEAD` 后重新分组提交 |
| 无暂存 + 有未暂存 | 全部变更 | 直接分组提交 |

未暂存的修改可能属于别的功能,不得混入本次提交,提交完成后必须恢复。仓库还没有初始提交时 `git stash push --keep-index` 会失败,此时直接提交索引内容即可。

### 5. 分组

按「分组决策原则」先出方案,再动手:

```
分组方案:
组 1: [文件列表]
  → type: <type>
  → scope: <scope>
  → subject: <描述>
```

### 6. 逐个分组提交

```
for 每个分组:
    git add <files>
    按 Commit Message 规范生成消息
    过一遍「提交前检查」后提交
```

多行正文用 heredoc:

```bash
git commit -m "$(cat <<'EOF'
feat(scope): subject

- 修改项 1
- 修改项 2
EOF
)"
```

| 提交前检查 | 风险 | 处理 |
|-----------|------|------|
| 密钥 / 密码 / token | Critical | 停止提交,移除后再来 |
| `console.log` / `TODO` / `debugger` | Warning | 移除或确认保留 |
| 二进制文件 / >1MB 大文件 | Warning | 确认该不该提交,必要时建议写入 `.gitignore` |

### 7. 验证与恢复

```bash
git log --oneline -N          # 提交数量应与分组方案一致
git show                      # 检查最新提交内容
git stash pop && git status   # 仅当第 4 步保存过未暂存内容
```

### 8. 异常处理

| 异常 | 处理 |
|------|------|
| 提交消息写错 | 仅最新提交且未推送时 `git commit --amend` |
| 漏掉文件 | 仅最新提交且未推送时 `git add <file> && git commit --amend` |
| 分组错误 | `git reset --soft HEAD~N` 后重新分组 |
| pre-commit hook 失败 | 展示原始错误,不自动绕过 |
| stash 恢复冲突 | 报出冲突文件,不自动 `git stash drop` |

## Commit Message 规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

**type**:`feat` 新功能 · `fix` 缺陷修复 · `docs` 文档 · `style` 格式(不改逻辑) · `refactor` 重构 · `perf` 性能 · `test` 测试 · `chore` 构建/依赖/配置 · `security` 安全修复

**scope**:必需,kebab-case,取自变更模块/组件名;跨模块取最核心的模块名,或用 `core` / `misc`

**subject**:命令式语气(「添加」而非「添加了」)、≤50 字符、无句号、说「做了什么」而非「为什么」;禁止「更新代码」「修复错误」这类泛泛描述

**body**:多文件变更时用 `-` 列表逐条列出改动,可补背景与影响范围

**footer**:`Closes #123` / `Fixes #456` / `BREAKING CHANGE: 说明`

## 分组决策原则

- **一个文件 = 一个分组**:同一文件的改动禁止拆到多个提交
- 维度优先级递减:重命名/移动(新旧文件必须同组)→ 模块(同目录/同功能)→ 类型(模型/服务/视图/测试)→ 关注点(UI/逻辑/配置/测试)→ 回滚性(需一起回滚的放同组)

| 典型模式 | 文件组合 | 类型 |
|---------|---------|------|
| 功能开发 | 组件 + 样式 + 测试 | `feat` |
| 缺陷修复 | 源文件 + 测试修复 | `fix` |
| 重构 | 旧文件删除 + 新文件添加 + 引用更新 | `refactor` |
| 配置联动 | 配置文件 + 使用配置的代码 | `chore` 或 `feat` |

## 提交前检查清单

**绝不**:不相关变更混进同一提交 · 泛泛的提交消息 · 漏 scope · 结尾加句号 · 同一文件拆到多个提交 · 提交敏感信息或调试代码

**交付前逐项确认**:
- [ ] 范围已确定,分组方案已应用;每个提交目的单一,数量与方案一致
- [ ] 消息符合 Conventional Commits(含 scope,无句号)
- [ ] 保存过的未暂存内容已恢复
- [ ] 无敏感信息、无调试代码遗留

## 汇报格式

```
提交完成:
- <短 hash> <type>(<scope>): <subject>
- ...

暂存区: <已恢复未暂存内容 / 无未暂存内容 / 已清空>
异常: <无 / 具体情况>
```

</commit_rules>
