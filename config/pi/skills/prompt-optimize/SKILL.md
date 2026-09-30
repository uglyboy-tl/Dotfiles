---
name: prompt-optimize
description: 用现代模型的指令遵循规律审查并优化 prompt(agent 定义、斜杠命令模板、SKILL.md、AGENTS.md)。要写新 prompt,或发现 prompt 变长、规则重复、规则被忽略、模型过度自检、模型不动手时使用。
---

# Prompt 优化

## 前提

- 目标是**指令遵循**:写进去的规则真的被执行。token 是副产品,不是目标。
- 最小充分集不等于字数最少(Anthropic: minimal ≠ short):该写的事实、契约、判据一条都不能省;要删的是冗余与脚手架。
- 本 skill 的规则都针对**产出物**(你正在写或改的那个 prompt);除明确说明,不约束本文件的写法,也不禁止审查者自己的思考步骤。

## 第一原则

1. **事实与约定留下,思维脚手架删掉**:事实、项目约定、工具名与参数、输出契约留下;思维步骤、推理提示、自评分机制删掉。判法:删掉某句后,模型对目标与边界的理解不变,它就是脚手架。
2. **一条约束只出现一次**(OpenAI "State each instruction once"):重复不只是浪费,还会诱发错误行为,例如反复写「先问用户」会导致对安全操作也请示。唯一例外:超过一屏(约 40 行)的长 prompt,末尾可放一句短的长度或风格提醒。
3. **判据优于流程**:写「什么算完成、什么算失败」,而不是列十步过程。
4. **语气就事论事,并说明动机**:不用 `CRITICAL` / `MUST` 这类强调,也不让 emoji 或大写字母承载语义强度;官方对照:`CRITICAL: You MUST use this tool when...` → `Use this tool when...`。禁令要给理由。
5. **结构只在混排时用**:需要区分指令、上下文、示例、用户输入时才分节或加 XML 标签;单条规则不必包一层标签。
6. **输出模板只写字段与取值范围,不写具体取值**:模型会把模板里的字面值当成答案照抄。例:模板写 `结论: 通过`,报告就永远是「通过」;写 `置信度: 高`,每条问题都会填「高」;应写 `结论: {通过|提醒|拒绝}`。

## 逐项决策

| 元素 | 推荐做法 | 例外 |
|------|----------|------|
| 角色声明 | 一句话,或直接描述职责 | 需要特定语气时写清「怎么写」,不要用「友好」「专业」这类标签 |
| 强制 CoT | 删 | 模型思考关闭时(如 pi 里 thinking 设为 off)可用「think thoroughly」+ `<thinking>`/`<answer>`;非推理模型仍可用 |
| few-shot | 输出格式是产品要求、或实测存在缺口时才用,包在 `<example>` 里 | 不堆边界用例;示例必须与指令一致 |
| 自检、双查指令 | 删 | 有具体验收标准时写成判据,不写「再确认一遍」 |
| 笼统指令(「只报严重问题」「拿不准就用 X」) | 删。全报,每条标分级与置信度,由调用方过滤 | 无 |
| 工具说明 | 只暴露该任务需要的工具;工具自身的 description 简短精确 | 无 |
| 优先级 | 显式声明「用户指令优先于本文件」 | 无 |
| 委派判据 | 写清什么情况委派、什么情况自己做;能设上限就设 | 无 |
| 分级与汇总结论 | 每级写清触发条件,并给出汇总映射(如:有阻断性问题 → 拒绝;只有建议 → 通过) | 无 |

## 目标骨架

一句话职责 → 判据(完成 / 失败 / 分级映射) → 不可推导的流程与命令 → 输出契约(格式 + 长度) → 边界(不做什么、冲突时听谁的)

## 审计流程

1. 校准项目事实:核对项目里真实存在的东西(测试框架、工具名、路径、命令),不提不存在的流程;若被审 prompt 依赖容易被误读的项目状态(如 git 的索引与工作区混合态),在产出物里加一句环境说明。
2. 逐段归类:留下 事实与项目约定、工具与参数、输出契约、判据;删掉或合并 思维脚手架、重复、人格化(用「友好」「专业」代替行为描述)、强度性措辞(靠 `CRITICAL`、emoji 强调)。顺手做一次可复制性检查:模型会照抄的模板里不得出现具体取值。
3. 四问自审:核心指令能否更一目了然;逻辑是否自洽;最挑剔的读者会在哪一步失败;有没有更好的结构封装。
4. 一处一改,改完做一次对比:改动前后各在一个新会话里用同一请求跑一次,记录 结论、分级是否符合映射、输出行数(这三个值只供自己判断,不写进交付);结论变化就要判断是否变好,两次记录不一致就是不稳定,退回第 2 步重新归类。起新会话用 `subagent` 并设 `inherit_context: false`;当前会话没有 `subagent` 工具(例如你本身就是子代理)、起不了新会话,或审查是只读的、改后文本没有落盘,就跳过并在交付里注明「未做稳定性对比」。
5. 发现具有通用性的例外条件时,在交付末尾单列「建议回写本 skill」条目交由用户决定,不自行编辑本文件。

## 预算(个人约定,非官方结论)

| 类型 | 目标 |
|------|------|
| agent 定义 | ≤ 80 行 |
| 斜杠命令模板 | ≤ 30 行 |
| SKILL.md | ≤ 120 行 |
| AGENTS.md 每条规则(一个 bullet) | ≤ 2 行 |

计行不计空行与围栏行。超预算先按审计流程归类,不要直接砍内容,尤其不要为凑行数删掉排版空行。

## 交付

给出改动清单(位置 + 原问题 + 改法);改动行数(新增 + 删除,未原样保留的旧行计入删除)超过被审 prompt 总行数一半时给改写后的完整文本,否则只给改动的章节并列出未改动章节;无改动时只回一句「无需改动」。不逐段解释,不做自评表。

## 来源

- Anthropic,Prompting best practices:https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- Anthropic,Prompting Claude Opus 5(over-verification、评审口径、委派上限):https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5
- Anthropic,Effective context engineering for AI agents(right altitude、examples、minimal ≠ short):https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- OpenAI,Using GPT-6(leaner prompts、State each instruction once、优先级声明):https://developers.openai.com/api/docs/guides/latest-model
