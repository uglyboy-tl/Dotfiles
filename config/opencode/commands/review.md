---
description: 审查代码变更 [commit|branch|pr]，默认审查未提交的更改
agent: code-reviewer
subtask: true
---
<input>$ARGUMENTS</input>

## 确定审查范围

根据 `<input>` 内容判断审查类型：

1. **输入为空**：
   - 有未提交更改：审查未提交的更改（`git diff`、`git diff --cached`）
   - 无未提交更改：审查最近提交（`git show HEAD`）

2. **输入为 commit hash**（40位SHA或短哈希）：审查特定提交
   - `git show <input>`

3. **输入为分支名**：将当前分支与指定分支对比
   - `git diff <input>...HEAD`

4. **输入为 PR URL 或编号**（包含 "github.com" 或 "pull" 或数字）：
   - `gh pr view <input>` 获取 PR 上下文
   - `gh pr diff <input>` 获取 diff

5. **输入为具体描述**（非上述类型）：按描述要求进行针对性审查

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