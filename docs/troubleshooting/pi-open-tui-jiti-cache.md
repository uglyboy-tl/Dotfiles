# pi-open-tui jiti 缓存导致 thinkingPeek 报错

## 现象

pi-web 界面持续报错：

```
undefined is not an object (evaluating 'config.thinkingPeek.lines')
```

禁用 pi-open-tui 扩展、`/reload` 均无效，错误持续出现。

## 根因

pi 通过 **jiti** 加载 `.ts` 扩展，jiti 会将转译结果缓存到 `/tmp/jiti/`（文件名格式 `<prefix>-<basename>.<path-hash>.mjs`）。

1. pi-open-tui 在 9月11日从 **0.2.15** 升级到 **0.3.5**（新增 thinkingPeek 功能）
2. 但 `/tmp/jiti/open-tui-config.f58cc6b5.mjs` 和 `open-tui-index.d9d67ea4.mjs` 仍是 8月24日的旧缓存（无 thinkingPeek）
3. jiti 的 fs 缓存以**路径哈希**为 key，同路径的旧缓存未被自动失效
4. 结果：新 `index.ts`（访问 `config.thinkingPeek.lines`）+ 旧 `config.ts`（`DEFAULT_CONFIG` 无 thinkingPeek）= 运行时 `config.thinkingPeek` 为 `undefined`

### 为什么禁用/reload 不生效

- 禁用扩展只影响新 session 的绑定，已绑定的 session 继续使用内存中的旧模块
- `/reload` 重新加载模块，但 jiti 的 fs 缓存仍返回旧的转译产物
- **必须重启 pi-web 进程**才能让 jiti 重新转译

## 修复

```bash
# 1. 清除 jiti 缓存中的 open-tui 文件
rm -f /tmp/jiti/open-tui-*.mjs

# 2. 重启 pi-web 进程
kill 50621  # 或 killall bun（如果有多个 bun 进程需精确指定）
```

## 预防

升级 pi-open-tui 后，若 pi-web 仍在运行，建议：

```bash
rm -f /tmp/jiti/open-tui-*.mjs && systemctl --user restart pi-web
# 或手动 kill + 重启
```

## 参考

- jiti 缓存目录：`/tmp/jiti/`
- pi-open-tui 配置：`~/.config/pi/open-tui.json`
- pi 扩展加载：`pi-coding-agent/dist/core/extensions/loader.js`（`jiti.import`）
