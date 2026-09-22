---
description: 提交当前修改(委派给专用 git-committer agent,无 subagent 时自己按同一规范执行)
argument-hint: "[文件/模块/说明]"
---

用户指令:$ARGUMENTS

## 执行方式

判断规模只看 `git status --porcelain`(文件数与状态);**不要先把 `git diff` / `git log` 读进主对话** - 要读就交给子代理。

**变更多(要逐个看 diff)、或仓库不熟要多轮排查** → 委派给 `git-committer`:它自带规范与所需工具,不用你交代规范:

    subagent({
      subagent_type: "git-committer",
      description: "提交当前修改",
      inherit_context: false,
      prompt: "用户指令:$ARGUMENTS(为空表示无额外指令)。按你的 agent 定义完成范围判定、分组、提交与善后,不要提问,最后按其中的汇报格式输出。",
    })

跑完把结果如实汇报给用户(提交清单、暂存区状态、异常)。

**只有一两个文件、改动一眼能看清** → 你自己做:先 read ~/.config/pi/agents/git-committer.md,严格按其中的规范与流程提交,并按同样的格式汇报。

若 spawn 失败或提示 agent 类型未知,按上面「自己做」那条处理。不要询问用户,一路做完。
