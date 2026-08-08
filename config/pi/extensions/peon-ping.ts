/**
 * peon-ping for Pi (earendil-works/pi) — Thin Adapter
 *
 * 基于官方 oh-my-pi 适配器改写：把 pi 生命周期事件转发给 peon.sh，
 * 获得声音、桌面通知、终端 tab 标题等 peon-ping 全部能力。
 *
 * 事件映射 (pi → peon.sh hook_event_name):
 *   session_start    → SessionStart
 *   agent_start      → UserPromptSubmit   (一次用户请求 = 一次 agent run)
 *   agent_settled    → Stop               (agent 完全结束，不会自动继续)
 *   tool_result (isError) → PostToolUseFailure
 *   session_compact  → PreCompact
 *   session_shutdown → SessionEnd
 *
 * 注意：不用 turn_start/turn_end —— 单个请求内每轮 LLM 调用都触发，
 * 会造成开始音/完成音同一毫秒重叠。
 *
 * 依赖 peon-ping 已安装:
 *   brew install PeonPing/tap/peon-ping
 *   # 或: curl -fsSL peonping.com/install | bash
 *   # 或 PATH 里有 peon（如 ~/.local/bin/peon）
 */

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import { spawn } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const PEON_SH_PATHS = [
	path.join(os.homedir(), ".claude", "hooks", "peon-ping", "peon.sh"),
	path.join(os.homedir(), ".openclaw", "hooks", "peon-ping", "peon.sh"),
	path.join(os.homedir(), ".local", "share", "dotfiles", "scripts", "peon"),
];

function findPeonSh(): string | null {
	// 优先 PATH 里的 peon（用户已装 ~/.local/bin/peon）
	const pathEnv = process.env.PATH ?? "";
	for (const dir of pathEnv.split(path.delimiter)) {
		const p = path.join(dir, "peon");
		try {
			if (fs.existsSync(p)) return p;
		} catch {}
	}
	for (const p of PEON_SH_PATHS) {
		try {
			if (fs.existsSync(p)) return p;
		} catch {}
	}
	return null;
}

function setTabTitle(title: string): void {
	if (!process.stdout.isTTY) return;
	process.stdout.write(`\x1b]0;${title}\x07`);
}

export default function peonPingExtension(pi: ExtensionAPI): void {
	const peonSh = findPeonSh();
	if (!peonSh) {
		console.warn("[peon-ping] peon.sh not found. Install peon-ping first:");
		console.warn("  brew install PeonPing/tap/peon-ping");
		console.warn("  # or: curl -fsSL peonping.com/install | bash");
		return;
	}

	const cwd = process.cwd();
	const projectName = path.basename(cwd) || "pi";
	const sessionId = `pi-${Date.now()}`;

	// 3 秒防抖：同类型事件连发时只响一次（防止并行工具失败、极快请求重复出声）
	const lastFired = new Map<string, number>();
	function firePeon(event: string): void {
		const now = Date.now();
		const last = lastFired.get(event) ?? 0;
		if (now - last < 3000) return;
		lastFired.set(event, now);

		const payload = JSON.stringify({
			hook_event_name: event,
			notification_type: "",
			cwd,
			session_id: sessionId,
			permission_mode: "",
			source: "pi",
		});

		try {
			const proc = spawn("bash", [peonSh], {
				stdio: ["pipe", "ignore", "ignore"],
			});
			proc.stdin.write(payload);
			proc.stdin.end();
			proc.unref();
		} catch {}
	}

	pi.on("session_start", async (_event, ctx) => {
		if (ctx.hasUI) setTabTitle(`${projectName}: ready`);
		firePeon("SessionStart");
	});

	pi.on("agent_start", async (_event, ctx) => {
		if (ctx.hasUI) setTabTitle(`${projectName}: working`);
		firePeon("UserPromptSubmit");
	});

	pi.on("agent_settled", async (_event, ctx) => {
		if (ctx.hasUI) setTabTitle(`\u25cf ${projectName}: done`);
		firePeon("Stop");
	});

	pi.on("tool_result", async (event, ctx) => {
		if (!event.isError) return;
		if (ctx.hasUI) setTabTitle(`\u25cf ${projectName}: error`);
		firePeon("PostToolUseFailure");
	});

	pi.on("session_compact", async () => {
		firePeon("PreCompact");
	});

	pi.on("session_shutdown", async () => {
		firePeon("SessionEnd");
	});
}
