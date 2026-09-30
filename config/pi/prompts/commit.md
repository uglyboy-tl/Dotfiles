---
description: 提交当前修改(委派给专用 git-committer agent,无 subagent 时自己按同一规范执行)
argument-hint: "[文件/模块/说明]"
---

用户指令:$ARGUMENTS

用户指令优先于本文件;与下文冲突时按用户指令执行。

判断规模只看 `git status --porcelain`(文件数与状态);不要把 `git diff` / `git log` 读进主对话(会占满主上下文),要读就交给子代理。

委派给 `git-committer` 的条件:变更超过 2 个文件、需要逐个读 diff、或仓库不熟要多轮排查。它自带规范与所需工具,不用你交代规范:

    subagent({
      subagent_type: "git-committer",
      description: "提交当前修改",
      inherit_context: false,
      prompt: "用户指令:$ARGUMENTS(为空表示无额外指令)。按你的 agent 定义完成范围判定、分组、提交与善后,最后按其中的汇报格式输出。",
    })

`git-committer` 在后台运行,工具会立刻返回 `Agent started in background` 并结束本轮:此时只向用户回一句「已委派 git-committer 后台提交」,不要声称已经提交。等完成通知(`<task-notification>`)到达后,再如实转达提交清单、暂存区状态与异常。

其余情况(不超过 2 个文件、改动一眼能看清)自己做:先 read `$PI_CODING_AGENT_DIR/agents/git-committer.md`,按其中的规范与流程提交,并按同样的格式汇报。

只提交本次范围内的变更,不修改任何文件内容;不询问用户;spawn 失败或提示 agent 类型未知时,按「自己做」处理。
