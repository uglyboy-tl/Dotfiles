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
- **rofi 主题的 `border-radius` 要与 picom 的 `corner-radius` 保持一致**：不一致时 picom 的圆角遮罩会切掉 rofi 自己的圆角边缘，四角留一圈半透明白边（曾用 14px 而 picom 是 10px）。当前 picom `corner-radius = 10.0`，rofi 主题统一 `10px`。
- **btop 退出时会整份回写 `~/.config/btop/btop.conf`**：值会保留，但注释会被替换成它自己的英文注释，我们模板里的说明随之消失，改设置必须改 `themes/templates/btop.conf.tpl` 再渲染（或换一次主题）。也因此 `btop.conf` 不做 dotbot 软链，否则 btop 会把仓库文件写脏。
- **btop 1.3.2 没有独立 `gpu` 方框**：`presets` 里写 `gpu:0:default` 会被忽略，整条预设退化成只剩 proc 框；GPU 占用/显存/温度要通过 `show_gpu_info = "On"` 显示在 cpu 框内。
- **polybar `internal/*` 模块的 `click-left` 不触发（3.7.2 实测）**：给 `internal/cpu`、`internal/network` 配 `click-left` 点了没反应，而同一条 bar 上 `custom/script`（`date`）、`custom/text`（`powermenu`）的 `click-left` 正常。绕法是用 `%{A}` 标记把整个模块包起来：`format = %{A1:命令:}<label>%{A}`（写法见 `desktop/polybar/modules/date.ini`）。两个约束：`%{A1:...:}` 的命令里**不能含冒号**；命令由 shell 执行，所以 `$HOME` 能正常展开。
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

- **picom 的 rules 是"全有或全无"**：一旦定义 `rules`，`rounded-corners-exclude` / `shadow-exclude` / `blur-background-exclude` / `active-opacity` / `inactive-opacity` / `inactive-dim` / `wintypes` / `opacity-rule` / `mark-wmwin-focused` / `mark-ovredir-focused` 全部失效并逐条告警，行为只能搬进 rules。规则按书写顺序匹配，**同一选项以最后命中者为准**（默认值放前、特例放后）。rules 模式下全屏窗口不再自动去圆角，必须显式 `{ match = "fullscreen"; corner-radius = 0; }`。另外 `_COMPTON_SHADOW` 只在"没有 rules"的老路径里被读取，所以 polybar 的阴影开关改用自定义属性 `_POLYBAR_FLOAT`，且**属性存在表示「悬浮开」**：polybar 重载会重建窗口丢属性，丢失时正好回落到默认的关（无阴影），不会闪（见 [设置菜单](settings.md)）。
- **polybar 已不显示 cpu/memory/temperature**：这三个模块连同 rofi 系统信息面板都已删除，硬件状态改在终端看 btop。若从 git 历史恢复旧配置，注意 `md-memory` 画出来是方形芯片、`fa-microchip` 是竖条，两个字形不可对调。
- **`idle-screensaver.sh -h` 从脚本自身的注释段读取用法**（grep `# 用法:` 到下一个空注释行），头部那段注释是功能的一部分，格式不能随手改。
- **`brightness` 受 DDC/I2C 约 300ms 的硬件下限约束**：所以本机状态立刻反馈通知，`setvcp` 丢后台并用 `flock` 串行，避免连按时排队卡住。
- **壁纸的 crontab 行必须写全 `DISPLAY` / `XAUTHORITY` / `DBUS_SESSION_BUS_ADDRESS` / `PATH`**：cron 环境里没有这些。
- **zsh 的几处顺序约束**：`path` 关联数组开了 `-U` 去重后必须用数组式赋值（`PATH=...` 字符串式不去重）；`zsh-users/zsh-completions` 必须在 `zicompinit` 之前加载，否则新补全不进 compinit；`ZSH_AUTOSUGGEST_MANUAL_REBIND=1` 靠"不再每个 prompt 重绑 ZLE widget"提速，一旦新增包装 ZLE 的插件就要删掉这行；atuin 必须 `--disable-ctrl-r --disable-up-arrow`，否则后加载的 `OMZP::fzf` 会抢走绑定。
- **starship 的 `[cmd_duration]` 必须把 `$cmd_duration` 写进顶部 `format`**，否则整段配置不生效。
- **fontconfig 的 monospace 回退链是固定的**（Hack → Sarasa → Noto CJK → Maple）：设置菜单的字体项会重写该块并移除其他字体，手工往里加字体会破坏回退顺序。
- **GitHub 加速走 `gh-proxy.com`**：实测 clone 37MB 约 3.5s，直连时通时断。备选：`ghfast.top`（大文件稍快）、自建 `xget.uglyboy.cn/gh/`（LAX 节点，git 不稳定）。配置在 `config/git/config` 的 `url.insteadOf`。
- **Edge 企业策略只保留 Linux 实测生效的条目**：微软政策文档列的是全平台策略，Windows 专属项（`MetricsReportingEnabled`、`DiagnosticData`、`StartupBoostEnabled` 等）在 Linux 上报「未知策略」并被静默忽略。改策略后必须完全退出 Edge 再启动；校验看 `edge://policy`（或该页「导出到 JSON」）里每条有无 `error` 字段。

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
