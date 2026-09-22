---
name: research
description: 深度研究:多轮检索 + 交叉验证,产出带引用来源的完整报告。用户要求「研究/调研/查证/核实/对比/评估选型/找最佳实践/确认某说法」,或需要多个外部来源才能回答的问题时使用。支持 quick / standard / deep 三档深度。
---

# 深度研究

问题与档位在末尾的 `User:` 行(首词是 `quick` / `standard` / `deep` 时去掉该词作档位,没有就是 `standard`)。若是你自己判断该用本 skill,问题即当前用户请求。

## 执行方式

委派与否看**材料和结论的性质**,不看档位标签:

| 情况 | 做法 |
|------|------|
| 读几个本地文件就能答(材料约 1 万 token 以内)、结论不需要交叉验证 | 自己做 - 委派的固定开销(preamble + 研究协议 + 启动)比省下的材料还多 |
| 要读大量外部页面 / 多个来源 / 结论需要独立核查 | 委派 - 材料读完即弃,不该占着主对话,还会拖累后续判断 |
| 材料本身是后续工作的依据(要接着改那个文件) | 自己做 - 留在主对话里有用 |
| 主对话已很长,再多塞材料可能触发压缩 | 委派 - 压缩会丢掉早期任务要求 |
| 用户明确说「用 subagent / 委派」 | 委派,这是用户意志 |

**委派**给 `researcher`(它自带联网与检索工具,规则就在它的定义里,你不需要交代规范)。委派前不要先自己 `web_search` / `fetch_content`:

    subagent({
      subagent_type: "researcher",
      description: "深度研究: <问题摘要>",
      inherit_context: false,
      prompt: "用户问题:<问题>。档位:<quick|standard|deep>。",
    })

拿到结果后原样呈现给用户(报告本身就是交付物)。若 spawn 失败或提示 agent 类型未知,改用下面的方式。

**没有 `subagent`** → 你自己执行:先 read ~/.config/pi/agents/researcher.md,严格按其中的研究协议完成检索与验证,并输出同样的 evidence / answer / next_steps 三段。
