/**
 * herdr-sidebar-task — 把 pi 会话的任务名报给 herdr 侧栏的 $task token
 *
 * 背景：同一个 workspace 下开多个 pi 时，herdr 侧栏里这些 agent 的
 * workspace / tab 名完全一样（tab 名派生自 peon-ping 写的终端标题），
 * 只有状态图标不同，无法区分哪个是哪个。pane metadata token 是 herdr
 * 唯一允许自定义的区分来源。
 *
 * 配合 config/herdr/config.toml：
 *   [ui.sidebar.agents]
 *   rows = [["state_icon", "$task"]]
 *
 * 取会话首条用户消息的首行作为任务名，整会话只上报一次（稳定标签），
 * 同时把任务名写成 herdr tab 名（RENAME_TAB = false 可关）。
 * 只在 herdr 管理的 pane 内生效；其他终端下静默退出。
 *
 * 自检：HERDR_SIDEBAR_TASK_SELFTEST=1 bun config/pi/extensions/herdr-sidebar-task.ts
 *
 * 注意：不要用 import.meta 的 main 标志做自检开关。扩展被 jiti 转成 CJS 加载，
 * import.meta 会把加载路径逼到 data: URL，并发启动多个 pi 时超出 bun 解析器的
 * 长度上限，报 NameTooLong 导致扩展整个加载失败。环境变量守护没有这个问题。
 */

import net from "node:net";

const socketPath = process.env.HERDR_SOCKET_PATH;
const paneId = process.env.HERDR_PANE_ID;
const tabId = process.env.HERDR_TAB_ID;
const source = "herdr:pi-task";

/** 侧栏宽度默认 26 列，减掉 state_icon 和分隔符后留给任务名的格数 */
const MAX_CELLS = 22;

const socketEndpoint =
	process.platform === "win32" && socketPath ? `\\\\.\\pipe\\${socketPath}` : socketPath;

function enabled(): boolean {
	return process.env.HERDR_ENV === "1" && !!socketPath && !!paneId;
}

/**
 * 东亚宽字符占 2 格。只覆盖 CJK 常用区段，够用且无需引入 wcwidth 依赖。
 */
function charWidth(cp: number): number {
	return (cp >= 0x1100 && cp <= 0x115f) || // Hangul Jamo
		(cp >= 0x2e80 && cp <= 0xa4cf) || // CJK 部首 .. 彝文
		(cp >= 0xac00 && cp <= 0xd7a3) || // Hangul 音节
		(cp >= 0xf900 && cp <= 0xfaff) || // CJK 兼容表意
		(cp >= 0xfe30 && cp <= 0xfe6f) || // CJK 兼容形式
		(cp >= 0xff00 && cp <= 0xff60) || // 全角形式
		(cp >= 0xffe0 && cp <= 0xffe6) ||
		(cp >= 0x20000 && cp <= 0x3fffd) // CJK 扩展 B 及以上
		? 2
		: 1;
}

/** 按显示宽度截断，超出时留 1 格放省略号 */
function clampWidth(s: string, max: number): string {
	let width = 0;
	let out = "";
	for (const ch of s) {
		const cw = charWidth(ch.codePointAt(0)!);
		if (width + cw > max) break;
		out += ch;
		width += cw;
	}
	if (out.length === s.length) return out;
	while (out.length > 0 && width + 1 > max) {
		const last = out[out.length - 1];
		width -= charWidth(last.codePointAt(0)!);
		out = out.slice(0, -1);
	}
	return `${out}…`;
}

/**
 * 去掉注入块。`/skill:xxx` 会把整份 SKILL.md 当作首条用户消息塞进来，
 * 真正的提问在 `</skill>` 之后；不剥离的话任务名会变成 `<skill name="...">`。
 */
function afterInjection(text: string): string {
	const marker = text.lastIndexOf("</skill>");
	return marker >= 0 ? text.slice(marker + "</skill>".length) : text;
}

/** 取首条用户消息文本的首个有效行，压平空白并截断 */
function summarize(text: string, max = MAX_CELLS): string | undefined {
	const line = afterInjection(text)
		.split("\n")
		.map((l) => l.trim())
		// 跳过纯标签行（注入块的残留）
		.find((l) => l.length > 0 && !/^<[^>]*>$/.test(l));
	if (!line) return undefined;
	const flat = line.replace(/^[#>\s]+/, "").replace(/\s+/g, " ");
	if (!flat) return undefined;
	return clampWidth(flat, max);
}

/** 用户消息的 content 可能是字符串，也可能是 text/image 片段数组 */
function textOf(content: unknown): string | undefined {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return undefined;
	const parts: string[] = [];
	for (const part of content) {
		if (part && typeof part === "object") {
			const p = part as { type?: unknown; text?: unknown };
			if (p.type === "text" && typeof p.text === "string") parts.push(p.text);
		}
	}
	return parts.length > 0 ? parts.join("\n") : undefined;
}

/** 调 herdr socket API，fire-and-forget */
function send(method: string, params: Record<string, unknown>): void {
	if (!enabled()) return;
	const socket = net.createConnection(socketEndpoint!);
	socket.on("error", () => socket.destroy());
	socket.on("connect", () =>
		socket.write(
			`${JSON.stringify({
				id: `${source}:${Date.now()}:${Math.random().toString(36).slice(2)}`,
				method,
				params,
			})}\n`,
		),
	);
	socket.on("data", () => socket.destroy());
	socket.unref?.();
}

/** 上报或清除 $task。task 为 undefined 时清除。 */
function reportTask(task: string | undefined): void {
	send("pane.report_metadata", {
		pane_id: paneId,
		source,
		tokens: { task: task ?? null },
	});
}

/**
 * 把任务名写成 herdr tab 名。只在拿到真实任务名时调，不用目录名兜底值，
 * 否则手动改过的 tab 名会在每次重启会话时被冲掉。
 * 不想自动改 tab 名就把 RENAME_TAB 改成 false。
 */
const RENAME_TAB = true;

function renameTab(label: string): void {
	if (!RENAME_TAB || !tabId) return;
	send("tab.rename", { tab_id: tabId, label });
}

export default function herdrSidebarTask(pi: any): void {
	if (!enabled()) return;

	// 真正的任务名是否已上报；未上报时允许用目录名兜底占位
	let taskReported = false;

	function captureFrom(text: string | undefined): void {
		if (taskReported) return;
		const task = text ? summarize(text) : undefined;
		if (!task) return;
		taskReported = true;
		reportTask(task);
		renameTab(task);
	}

	/** 取不到任务名时的占位，避免侧栏只剩一个认不出是谁的图标 */
	function fallbackName(): string | undefined {
		const base = process
			.cwd()
			.replace(/[\\/]+$/, "")
			.split(/[\\/]/)
			.pop();
		return base ? clampWidth(base, MAX_CELLS) : undefined;
	}

	pi.on("session_start", (_event: any, ctx: any) => {
		// 恢复/分叉的会话里已有历史，从分支上取首条用户消息
		try {
			const branch = ctx?.sessionManager?.getBranch?.() ?? [];
			for (const entry of branch) {
				if (entry?.type === "message" && entry.message?.role === "user") {
					captureFrom(textOf(entry.message.content));
					break;
				}
			}
		} catch {
			// 拿不到历史就算了，等 message_end 兜底
		}
		if (!taskReported) reportTask(fallbackName());
	});

	pi.on("message_end", (event: any) => {
		if (event?.message?.role !== "user") return;
		captureFrom(textOf(event.message.content));
	});

	pi.on("session_shutdown", () => {
		// pane 会被复用成普通 shell，清掉免得留下过期任务名
		reportTask(undefined);
	});
}

// ---- 自检 ----
if (process.env.HERDR_SIDEBAR_TASK_SELFTEST === "1") {
	const assert = (ok: boolean, msg: string) => {
		if (!ok) throw new Error(`FAIL: ${msg}`);
		console.log(`ok: ${msg}`);
	};

	assert(clampWidth("abc", 10) === "abc", "短串不截断");
	assert(clampWidth("abcdefghij", 5) === "abcd…", "ASCII 截断留省略号");
	assert(clampWidth("研究herdr插件", 8) === "研究her…", "CJK 按 2 格计算");
	assert(clampWidth("研究", 3) === "研…", "宽字符边界：给省略号腾 1 格");
	assert(charWidth("a".codePointAt(0)!) === 1, "ASCII 宽 1");
	assert(charWidth("研".codePointAt(0)!) === 2, "CJK 宽 2");

	assert(summarize("\n\n  hello world  \nsecond") === "hello world", "取首个非空行并压平");
	assert(
		summarize('  <skill name="research">\n\n# 深度研究\n\n规则…\n</skill>\n\n帮我研究 herdr 插件') === "帮我研究 herdr 插件",
		"剥掉 skill 注入块，取 </skill> 之后的真实提问",
	);
	assert(
		summarize('<skill name="x">\n内容\n</skill>\n\n<tag only>\n真实问题') === "真实问题",
		"注入块后紧跟标签行时继续往下找",
	);
	assert(summarize("<skill name=\"x\">\n只有注入没有提问\n</skill>") === undefined, "只有注入块时返回 undefined");
	assert(summarize("## 帮我研究一下 herdr") === "帮我研究一下 herdr", "剥掉 markdown 标题标记");
	assert(summarize("   \n  ") === undefined, "全空白返回 undefined");
	assert(summarize("") === undefined, "空串返回 undefined");
	assert(
		summarize("a".repeat(100)) === `${"a".repeat(21)}…`,
		"超长首行按宽度截断",
	);

	assert(textOf("plain") === "plain", "字符串 content");
	assert(
		textOf([
			{ type: "text", text: "看图" },
			{ type: "image", data: "x" },
		]) === "看图",
		"片段数组只取 text",
	);
	assert(textOf([{ type: "image", data: "x" }]) === undefined, "纯图片无文本");
	assert(textOf(undefined) === undefined, "undefined content");
}
