# 维护笔记

面向本仓库**维护者**：Git 索引技巧、预览缓存、已知问题、待办。
日常与扩展不需要读这里（想加东西看 [扩展指南](extending.md)）。

## 版本控制

### 渲染产物（`.gitignore`）

主题渲染产物会经目录级软链落回仓库，需要被忽略。`.gitignore` 用 **`desktop/*/colors.*`**——限定在 `desktop/` 下一层，既覆盖所有（含未来的）桌面产物，又碰不到 `themes/` 下的源文件。**不要**改回 `**/colors.*`：那个无差别通配曾静默吃掉全部 `themes/colors/<theme>/colors.toml`。原因与本末见 [ADR-0001](adr/0001-gitignore-colors-artifacts.md)。

**产物落在 `desktop/` 之外时**（如 `config/`），才需要为它单独加一条规则。

### 本地改动不追踪（skip-worktree）

`desktop/fontconfig/fonts.conf` 会被设置菜单的"字体"项改写。仓库需要保留一份默认版本供初次安装，但不希望记录本机的字体偏好，因此对本机该文件启用 Git 的 `skip-worktree`：

```sh
git update-index --skip-worktree desktop/fontconfig/fonts.conf
```

- 这是**本地索引标志，不随仓库提交**；换机器或重新 clone 后需重新执行一次。
- 文件仍被跟踪，仓库保留已提交的默认版本；本地改动留在磁盘但不进 `git status`。
- 需要主动提交一次本地改动、或与上游同步该文件时：

```sh
git update-index --no-skip-worktree desktop/fontconfig/fonts.conf
# 处理（commit / checkout / stash）后，再设回 --skip-worktree
```

- `config/pi/settings.json` 同样会被设置项改动，但**暂不**做此处理，保持正常追踪（它会稳定出现在 `git status` 里，属预期）。

## 预览缓存

预览图按 UI 分工，各取所长：

- **fzf（TUI）**：`img-preview.py` 导入 `image_cache.py`，把缩放后的预览 PNG 缓存到 `$XDG_CACHE_HOME/image-cache/`。缓存键 = sha1(源路径 + mtime + 大小 + 目标尺寸)，源变化自动失效；写入时清理过期条目。JPEG 大图首次缩放开销大（约 150ms），命中约 0.2ms。
- **rofi（GUI）**：直接传原图路径，由 rofi 自行加载与缓存图片——避免 rofi 弹出前串行为每项 spawn 子进程导致打开变慢。

> 清空 fzf 缓存：`rm -rf ~/.cache/image-cache`。

## 已知问题

- **sxhkd 启动 EPIPE**：快捷键启动时 stdout 是 socket，`echo` 会触发 SIGPIPE 中断脚本（`set -e` 下直接退出）。`epipe_init()` 忽略 SIGPIPE，且非 tty 时把输出重定向到 `~/.local/state/settings/logs/<脚本名>.log`。
- **bspwm 重载吞通知**：`bspc wm -r` 会重跑 bspwmrc，其中 `_s dunst` 会重启 dunst，导致刚发的通知被吞。主题切换因此先重载各软件、等新 dunst 就绪（`wait_dunst_ready`）再 `notify`。
- **feh 不能播 GIF 动画**：实测只显示第一帧。所以 `desktop/idle-screensaver.sh` 目前仅轮播静态图；动态屏保需改用 `mpv`（见待办）。
- **屏保不依赖 X screensaver 扩展**：该扩展常被应用挂起，导致 `xset s` 超时与 `xss-lock` 都不可靠。故屏保改用 `xprintidle` 轮询空闲时间实现（`xset s off` 只负责关掉 X 自带黑屏）。

## 待办

- opencode / pi agent - 检查是否支持主题配置
- vscode - 参考 Omarchy 的 `vscode-theme.json.tpl`
- 屏保支持动态：用 `mpv --no-audio --loop-playlist` 播放 GIF/视频（feh 只显示 GIF 第一帧）
- `xss-lock` 已不需要（屏保改走 `xprintidle`），确认后可从系统卸载

## 相关

- 内部脚本 API（`settings/lib/` 各函数职责）见 [架构与设计 → 脚本分层](architecture.md#脚本分层) 与 [设置菜单](settings.md)
- 面向 AI 助手与本仓库的通用约定另见根目录 [`AGENTS.md`](../AGENTS.md)
