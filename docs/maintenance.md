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

- **jellyfin-mpv-shim 的 `conf.json` 有意不纳管**：`conf.py:load()` 只要文件字段数少于 schema 就立刻写回全量（实测 10 项 262 B 一次加载后变 196 项 5858 B），所以无法精简；`save()` 用 `os.replace`，会把软链替换成普通文件，导致仓库副本过期、再跑 `./install` 时被 `force` 覆盖而丢设置。故只纳管 `desktop/systemd/jellyfin-mpv-shim.service`。本机有意的偏离项（其余取默认）：`mpv_ext=true`、`mpv_ext_no_ovr=true`、`osc_style="custom"`、`enable_gui=false`、`fullscreen=true`、`hwdec="no"`、`direct_paths=true`、`thumbnail_enable=false`、`check_updates=false`、`segment_intro="always"`。
- **sxhkd 启动 EPIPE**：快捷键启动时 stdout 是 socket，`echo` 会触发 SIGPIPE 中断脚本（`set -e` 下直接退出）。`epipe_init()` 忽略 SIGPIPE，且非 tty 时把输出重定向到 `~/.local/state/settings/logs/<脚本名>.log`。
- **bspwm 重载不再重启 dunst**：dunst 配色由 `themes/render.conf` 里的 `dunstctl reload` 应用，bspwmrc 只用 `_o dunst`（已在跑就不动），所以 `bspc wm -r` 不会吞掉刚发的通知（旧实现 `_s dunst` + `wait_dunst_ready` 已删；前提：dunst 支持 `dunstrc.d` drop-in，`dunstctl reload` 会连同它一起重读）。
- **feh 不能播 GIF 动画**：实测只显示第一帧。所以 `desktop/idle-screensaver/idle-screensaver.sh` 目前仅轮播静态图；动态屏保需改用 `mpv`（见待办）。
- **屏保不依赖 X screensaver 扩展**：该扩展常被应用挂起，导致 `xset s` 超时与 `xss-lock` 都不可靠。故屏保改用 `xprintidle` 轮询空闲时间实现（`xset s off` 只负责关掉 X 自带黑屏）。
- **`themes/capture.sh` 有两个坑（都是踩过才修的）**：
  1. **`bspwmrc:28-36` 写死了 `DP-0` 的原生分辨率**，而换主题会触发 `bspc wm -r` → bspwmrc 重跑 → 把截图用的 2560x1440 顶回 3440x1440。所以批量模式**每轮套用主题后都要重新 `set_capture_mode`**（否则截出来是 1280x536 而不是 1280x720，静默出错）。`shoot()` 里另有一句尺寸断言把这类错现出来。
  2. **恢复分辨率时必须同时给 `--rate 120`**。只给 `--mode 3440x1440` 的话 xrandr 会选它的 preferred（60Hz），跑完一次批量截图显示器就降频了。
- **`desktop/{bspwm/colors.sh, zathura/colors.conf}` 是陈旧残留**（2026-09），不是产物：`~/.config/bspwm` 现已是真实目录、`zathura` 未安装，产物不再落在这里。已被 `desktop/*/colors.*` 忽略所以不影响 git，但**比对这些文件的 mtime 会得出错误结论**（曾据此误判 bspwm 没被渲染）。`zathura` / `urxvt` 未安装 → 不渲染属预期行为。
- **`~/.config/{alacritty,ghostty,polybar,rofi,zathura}` 是软链到 `desktop/`，其余不是**：`dunst` / `bspwm` / `gtk-3.0` / `gtk-4.0` / `X11` / `fcitx5` 都已是真实目录，产物就地生成（不带进仓库）。所以判断「产物在不在仓库里」不能一概而论。
- **看视频会弹屏保（已修）**：`xprintidle` 只看键鼠输入，而浏览器抑制屏保走两条路——D-Bus `org.freedesktop.ScreenSaver`（bspwm 裸装没有该服务，请求落空）或 X11 `XScreenSaverSuspend`（只暂停 X 自带屏保，`xprintidle` 照涨）。故新增 `desktop/idle-screensaver/idle-screensaver-dbus.py` 补上这个 D-Bus 服务（心跳文件每秒刷新，服务死掉 5 秒后抑制自动失效），并在 `idle-screensaver.sh` 里按「D-Bus 抑制 / 全屏窗口 / 有音频输出流」三者任一成立就暂不出屏保、同时 `xset -dpms` 关熄屏。（该服务现由 systemd user unit `desktop/systemd/idle-screensaver-dbus.service` 常驻。）

## 上游生态观察

### tmux（查于 2026-10，数据源 `gh api`，可复现）

**结论**：tmux 本体正处最活跃期（3.6 → 3.8 连发八个版本），但官方插件组织 `tmux-plugins` 与几个历史名插件已实质停摆。**当前 3.5a，暂不升级**。

- **版本路径**：本机 3.5a；trixie-backports 有 3.6b（`apt -t trixie-backports install tmux`，5 分钟）；3.7/3.8 **无 backport，需源码编译**。
- **3.8（2026-09-09）值得升的理由**：内置明暗主题 + `themeblack`/`themedarkgrey` 等主题色名 + 颜色可作 format 展开 → **可删掉 `nord-tmux`**（该官方端口 2023-05 已停更，且硬编码不跟随终端切换）；`set-hook -B` 监视器与 `wait-for -E` 事件可用于通知联动；`switch-mode`（Tab 模糊切换）；浮动 pane 补完。
- **3.9 计划**：浮层完全取代 popup，`display-popup` 保留但语义变为模态浮动 pane——会影响 `config/tmux/tmux.conf` 里的 `bind-key p display-popup -E -w 80% -h 80%`。

本仓库用到的 tmux 依赖的最后提交：

| 依赖 | 最后提交 | 状态 |
|------|----------|------|
| `tmux-plugins/tpm` | 2023-02（代码） | 101 issue / 44 PR 积压 |
| `nordtheme/tmux` | 2023-05-03 | 停滞 |
| `tmux-plugins/tmux-sensible` | 2022-08-14 | 停滞 |
| `tmux-plugins/tmux-pain-control` | 2021-08-09 | 停滞 |
| `MunifTanjim/tmux-suspend` | 2023-01-15 | 非 tmux-plugins 组织，停滞 |
| `tmux-plugins/tmux-prefix-highlight` | 2025-03-01 | 组内唯一仍活跃 |

均为「停滞但稳定」，暂无替代压力。替代品 `tmuxpack/tpack` 目录布局与 TPM 不兼容、文档自认 AI 生成，**不建议迁移**。

**决策**：暂不升级。复查触发条件：① 需要 OSC 133 事件 / 监视器做通知联动；② 终端明暗切换需要 tmux 跟随（当前 nord-tmux 硬编码）；③ 3.9 发布后 popup 语义变更波及现有绑定。

**其他生态观察**（仅记录，不引入）：主题渲染器类工具（matugen / wpgtk / hellwal / pywal）与仓库 `themes/` 完全同构，属反向重复造轮子；若要新增会话管理优先看 `joshmedeski/sesh`；copy/hint 类优先看 `laktak/extrakto`（Python + fzf，复用已有组件）。

## 待办

- vscode - 参考 Omarchy 的 `vscode-theme.json.tpl`
- 屏保支持动态：用 `mpv --no-audio --loop-playlist` 播放 GIF/视频（feh 只显示 GIF 第一帧）

## 相关

- 内部脚本 API（`settings/lib/` 各函数职责）见 [架构与设计 → 脚本分层](architecture.md#脚本分层) 与 [设置菜单](settings.md)
- 面向 AI 助手与本仓库的通用约定另见根目录 [`AGENTS.md`](../AGENTS.md)
