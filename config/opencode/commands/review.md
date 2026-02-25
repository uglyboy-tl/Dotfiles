---
description: 审查代码变更 [commit|branch|pr]，默认审查未提交的更改
agent: code-reviewer
subtask: true
---

Input: $ARGUMENTS
---

## 确定审查范围

根据输入决定审查类型：

1. **无参数（默认）**：审查所有未提交的更改
   - `git diff` 查看未暂存的更改
   - `git diff --cached` 查看已暂存的更改
   - `git status --short` 识别未跟踪的新文件

2. **Commit hash**（40位SHA或短哈希）：审查特定提交
   - `git show $ARGUMENTS`

3. **分支名**：将当前分支与指定分支对比
   - `git diff $ARGUMENTS...HEAD`

4. **PR URL 或编号**（包含 "github.com" 或 "pull" 或类似 PR 编号）：
   - `gh pr view $ARGUMENTS` 获取 PR 上下文
   - `gh pr diff $ARGUMENTS` 获取 diff

## 获取上下文

**仅看 diff 不够。** 获取 diff 后，需阅读修改文件的完整内容才能理解上下文。

- 用 diff 识别改动的文件
- 用 `git status --short` 识别未跟踪文件，阅读其完整内容
- 阅读完整文件以理解现有模式、流程控制和错误处理
- 检查项目的风格指南或约定文件（CONVENTIONS.md、AGENTS.md、.editorconfig 等）

## 标记前确认

- 只审查变更的部分，不要审查未修改的原有代码
- 不确定时不要标记为 bug，先调查
- 不要创造假设问题
- 不要过度纠结风格，除非明显违反项目约定

## 输出风格

- 直接清晰，不过度夸大严重程度
- 描述 bug 产生的具体场景
- 语气实事求是，避免客套话
- 读者能快速理解

## 工具

- **Explore agent** - 查找现有代码如何处理类似问题
- **Exa Code Context** - 验证库/API 的正确用法
- **Exa Web Search** - 研究最佳实践

不确定时，说"我不确定 X"而非将其标记为确定问题。