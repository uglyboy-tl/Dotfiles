---
description: 审核代码变更 [commit|branch|pr|路径],默认审核未提交的更改(委派给专用 reviewer agent,无 subagent 时自己按同一规范执行)
argument-hint: "[commit|branch|pr|路径]"
---

用户指令:$ARGUMENTS

用户指令优先于本文件;与下文冲突时按用户指令执行。

判断范围只看 `git status --porcelain` 与用户指令;不要把 `git diff` / `git show` 读进主对话(会占满主上下文),要读就交给子代理。

委派给 `reviewer` 的条件:变更超过 2 个文件、范围是 commit/branch/pr、或需要读完整文件与历史上下文。它自带审核规范与所需工具,不用你交代规范:

    subagent({
      subagent_type: "reviewer",
      description: "审核代码变更",
      inherit_context: false,
      prompt: "用户指令:$ARGUMENTS(为空表示审核未提交的更改)。按你的 agent 定义执行,并按其中的输出格式给出完整报告。",
    })

上面是参数清单,不是已经执行的调用:委派成功的判据是 `subagent` 返回了 agent ID,回话要能写出这个 ID,写不出就是没委派——重发调用或按「自己做」处理,不要写「已委派」。

委派成功后本轮即结束,但不要声称已审核完;完成通知(`<task-notification>`)到达后再如实转达已审核文件、结论与按级别排列的问题。

其余情况(不超过 2 个文件、改动一眼能看清)自己做:先 read `$PI_CODING_AGENT_DIR/agents/reviewer.md`,按其中的维度、定级与输出格式审核并汇报。

只审变更部分,不改任何文件,不询问用户;调用失败或提示 agent 类型未知时,按「自己做」处理。
