# 与 Omarchy 的对比

> 调研日期：2026-09-28。Omarchy 当时最新版 4.0.4（Quattro 系列）。来源见[文末](#来源与时效)。
> Omarchy 迭代极快，本文超过 6 个月应重新核对（尤其「最新更新」一节）。

本项目大量参考 Omarchy（README 致谢「主题规范」，`Super+k` 快捷键菜单标注「仿 Omarchy」）。本文固化调研结论，避免重复劳动。

## 定位差异（先看这个）

| | Omarchy | 本仓库 |
|---|---|---|
| 形态 | Arch 发行版：ISO 安装器、自有签名包仓库、4 条更新通道、`omarchy` CLI | dotfiles + dotbot，`./install` 软链配置 |
| 职责边界 | 管软件**安装/更新/卸载** + 配置 | 只管**配置文件**；`./install setup` 用 apt 装一个 `jq`，其余软件归用户 |
| 会话 | Wayland + Hyprland | X11 + BSPWM |
| 桌面壳 | v3：Waybar + Walker + Mako + SwayOSD + hyprlock/gnome；v4：Quickshell 一体化 | Polybar + Rofi + Dunst（独立工具组合） |

共同理念：键盘优先的平铺桌面、omakase 式固定选型（不给选择题）、主题驱动的整体观感、一个聚合菜单做所有事。

## 软件选型对比

「取舍」列解释为什么两边不同，而不是谁更好。

### 桌面壳层

| 类别 | Omarchy | 本仓库 | 取舍 |
|---|---|---|---|
| 窗口管理 | Hyprland（动画/规则丰富，v4 配置全部 Lua 化） | BSPWM | Lua 表达力 vs `bspwmrc` 一个 shell 脚本直读；X11 让树莓派/老机器通用 |
| 快捷键 | Hyprland 内建 bindings | sxhkd | 同为声明式，sxhkd 可独立热重载 |
| 状态栏 | Waybar → v4 自研 Quickshell bar（拖拽换边、插件） | Polybar + 自研 scripts（电源/日历菜单） | 我们靠 Polybar 成熟生态；换取低耦合 |
| 启动器/菜单 | Walker → v4 原生 launcher，`Super+Space` 与 Omarchy 菜单合一、嵌套搜索 | Rofi（drun/window）+ 自研 `settings` 菜单 | 我们的 `settings` 是设置专用菜单，分工与 Omarchy 的 Setup 菜单等价 |
| 通知 | Mako → v4 自研通知（DND、去重、历史回放） | Dunst（`dunstrc.d` drop-in，主题 `dunstctl reload` 热重载；**兼做音量/亮度 OSD**） | Dunst 一物两用，换掉它等于同时失去 OSD；v4 的「通知历史回放」是少数值得抄的点 |
| OSD（音量/亮度） | SwayOSD → v4 内建原生 OSD | **复用 Dunst**：音量 `barify`、亮度 `brightness` 用 `dunstify -h int:value` 画进度条 | 省一个组件且自动继承主题；代价是走通知通道（脚本单独 `-t 1500` 短超时 + `-r` 复用通知 ID 避免堆积） |
| 锁屏/熄屏 | hyprlock → v4 shell PAM + 指纹 | 自研 `xprintidle` 轮询 + D-Bus 屏保抑制服务 | 裸 BSPWM 没有这些服务，自研是补位（排除 `xss-lock`，见 maintenance） |
| polkit | polkit-gnome → v4 内建 | 未纳管 | 我们少有 GUI 提权场景 |
| 合成器 | Hyprland 内建 | Picom（`bspwmrc` 启动行当前注释） | — |

### 终端与 Shell

| 类别 | Omarchy | 本仓库 | 取舍 |
|---|---|---|---|
| 终端 | v3 Alacritty → **v4 默认 Foot**（备选 Ghostty/Kitty/Alacritty） | 默认 **Ghostty**（Alacritty/URxvt 备选，三者都做主题） | Foot 是为资源占用换的（v4 同时换掉更重的字体）；我们默认 Ghostty 取 tabs/图片协议/GPU |
| Shell | zsh + Starship | zsh + Zinit + Powerlevel10k（Starship 已链接未启用） | 两边收敛到 zsh；提示符引擎不同而已 |
| 共同工具 | fzf、zoxide、ripgrep、bat 类似物 | fzf、zoxide、ripgrep、bat | 完全重合，说明是这类配置的事实标准 |
| 增强 | lazygit、lazydocker、`compress`/`fip` 等 shell 函数 | Atuin（历史）、binup（自研二进制管理）、xget 镜像 | 我们重「国内网络环境」（镜像加速），Omarchy 重 TUI 封装 |
| 会话复用 | tmux；**v4 起同装 Herdr**（键位与 tmux 对齐，`hdl`/`hds` 布局助手） | TMUX + TPM + nord-tmux，另有 **Herdr**（systemd 常驻 server，agent 会话宿主） | 少数两边选了同一工具的点；我们的 Herdr 用法更激进（常驻 + agent 侧栏） |
| 编辑器 | Neovim 默认（主题随主题生成）；VSCode/Cursor/Zed/Helix 可选装 | Vim + vim-plug；VS Code 仅窗口规则，主题接入暂缓 | 见 theming.md「评估过但不接入」：我们倾向不装编辑器扩展 |

### 应用与系统

| 类别 | Omarchy | 本仓库 | 取舍 |
|---|---|---|---|
| 浏览器 | Chromium | Edge（51 条企业策略：关 Copilot/遥测） | 我们按隐私收紧的是 Edge 而非换浏览器；Omarchy 不碰商业软件默认值 |
| 主题 | 19+ 主题；v4 扩到 **24 色语义色**，自动生成 nvim/VS Code/btop 配置 | 6 主题；终端定 16 色，CLI 跟随终端免模板，GUI 独立模板 | 我们模板更少但手维护；他们的「生成器」路线是明确的下一步参考 |
| 机器级覆盖 | v4 `~/.config/omarchy/shell.toml` 叠加在主题上，切主题不丢 | 无对等机制 | 我们的缺口，见下文借鉴清单 |
| 截图 | 自研（键盘驱动选区、QR 解码进剪贴板、OCR 提取） | maim 自研脚本（区域/全屏 + 剪贴板 + Dunst 通知） | 基础功能等价；QR/OCR 是他们独有的增值 |
| 壁纸 | 主题自带背景，切换器 `Super+Ctrl+Space` | dwall 动态壁纸（cron 每小时）+ feh | 我们要「动态」，他们要「跟主题走」 |
| 邮件 | 无内建（本次调研未见） | offlineimap + notmuch + NeoMutt + himalaya + pass | 我们明显更重的一块，Omarchy 不覆盖邮件 |
| 中文输入 | 未确认 | FCITX5 + RIME（雾凇拼音） | 我们必须有，他们面向英文用户 |
| 包管理 | pacman + 自有签名仓库 + AUR + `omarchy pkg add/drop` | apt（用户自装）+ binup + pip/uv/bun 镜像 | 我们不做安装层，故无更新通道/回滚问题 |
| 监控 | btop | btop（`Super+h`）+ FastFetch | 重合 |
| AI | v4 默认 agent **可选**（Claude Code/Codex/OpenCode/Pi/Gemini…），lazy-install，`c`/`cx` 别名 | Pi + OpenCode | 都收敛到「agent launcher」模式；他们做选择器，我们固定两个 |
| 游戏 | Steam/RetroArch/Lutris/Moonlight 等菜单化安装 | 未纳管（Steam/Lutris 仅窗口规则） | — |

## v4 Quattro 的更新：哪些值得借鉴

v4（2026-08-14）把整个桌面壳重写进 Quickshell，是项目成立以来最大的一次改动。逐条过后的结论：

### 值得借鉴（按性价比排序）

1. **主题生成编辑器配置**：24 色语义色 → 自动生成 nvim/VS Code/btop 配置。我们 `docs/maintenance.md` 已留 TODO、`docs/theming.md` 已记两种路线（装扩展 vs `colorCustomizations` 纯配置）；Omarchy 的 `vscode-theme.json.tpl` 就是现成参考。走我们倾向的纯配置路线。
2. **机器级覆盖层**：v4 `shell.toml` 叠加在主题之上，个人字体/间距调整切主题不丢。我们缺这一层，可加 `themes/` 用户覆盖（渲染顺序：主题 → 本地覆盖）。
3. **主题/设置不执行外部代码**：v4.0.1 修了「installed theme 跑代码」「shell 注入」一批漏洞。我们渲染第三方主题 `colors.toml`、`settings` 菜单拼命令行时同样要过一遍「外部字符串进 shell」路径。ADR-0003 不设 `vendor/`，更该注意脚本来源。
4. **事件驱动替代轮询**：v4 明确以信号驱动状态（空闲不烧 CPU）。我们 `xprintidle` 轮询、Polybar scripts 轮询、dwall cron 均属此类；不必立刻改，但新增轮询脚本前先想有没有信号源。
5. **通知历史回放**：dunst 自带 history（`dunstctl history-pop`），绑一个 `Super` 键即可等价实现 v4 的「找回最后十条通知」。
6. **字号统一旋钮**：v4 一个 `display text size` 同步 shell/GTK/终端。我们已有 `settings-font`（等宽字体切换），扩展成「字号」成本低。

### 暂不借鉴（有明确理由）

- **Quickshell 一体化壳**：v4 的核心，但在 X11 + BSPWM 下没有对应生态，等于重写整个桌面；Polybar/Rofi/Dunst 组合仍在维护期。
- **Foot 默认终端**：他们是为省内存/ISO 体积换的；我们默认 Ghostty 不缺这点资源。
- **Lua 化 Hyprland 配置**：不用 Hyprland，无对象。
- **发行版层能力**（自有包仓库、4 条更新通道、ISO、出厂重置、代装机器）：超出 dotfiles 职责边界。
- **agent 选择器**：我们固定 Pi + OpenCode，YAGNI。
- **网络/蓝牙/音频控制面板**：v4 内建的 ping/测速/Wi-Fi QR 面板，对我们这个体量是过度设计，Rofi 蓝牙菜单 + 网络管理器 TUI 已够。

## 来源与时效

- 发布说明：`gh api repos/omacom/omarchy/releases`（v4.0.4 = 2026-09-15，v4.0.0 Quattro = 2026-08-14，v3.8.x 为旧系列）
- 新手册（v4）：https://omarchy.org/manual/ ；旧手册（v3，含各软件章节）：https://learn.omacom.io/2/the-omarchy-manual
- 官网/包列表：https://omarchy.us/ 、https://distrowatch.com/table.php?distribution=omarchy
- 本文中「未确认」的条目（邮件、输入法、文件管理器默认项）为本次调研未覆盖，不要当结论引用。
