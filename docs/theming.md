# 主题系统

## 概述

自研主题渲染系统：`colors.toml`（颜色定义）+ `.tpl`（模板）→ 各应用配置。切换入口是 [设置菜单](settings.md)，当前主题记录在 `~/.local/state/theme/current`。

## 颜色策略

| 层次 | 应用类型 | 颜色来源 | 是否需要模板 |
|------|----------|----------|--------------|
| 源头 | 终端模拟器（Alacritty/Ghostty/URxvt） | 定义 16 色映射 | 需要 |
| 跟随 | CLI/TUI 工具（bat/zsh/neomutt/fastfetch/herdr/pi 等） | 继承终端 16 色 | 不需要 |
| 独立 | GUI 应用（Polybar/Rofi/Dunst/Zathura） | 独立颜色系统 | 需要 |
| 独立 | TUI 但不读终端调色板（btop） | 自带主题文件，颜色只能由模板写 hex | 需要 |

CLI 工具跟随终端的好处：一次切换全局生效，维护成本低。pi 的主题用 `config/pi/themes/flat.json`（`settings.json` 里 `theme = flat`），文件里**只写 ANSI 索引（0-255）和 `""`（终端默认色），不写 hex**——pi 把数字索引当 ANSI 转义序列输出，由终端用自己的调色板渲染（见 pi 的 `docs/themes.md`），所以换主题时 pi 的颜色跟着变。它不需要模板：**8 个主题渲染出的 `flat.json` 完全一样**。

> 不用 pi 内置的 `system` 主题：它会向终端查询前景/背景（OSC 10/11）和 16 色板（OSC 4;0-15），拿到颜色就给用户消息条、工具框刷底色。tmux 会代为转发/应答这些查询，于是**同一个主题在 tmux 里（如 NAS）有底色、在 tmux 外没有**。`flat` 把「无颜色回报」时的回退行为写死成静态主题，绕开了这个坑。

`flat.json` 里有两组槽位是**为了跟主题系统对齐**而刻意选的，不是随手填的（JSON 不允许写注释，理由记在这里）：

| 角色 | 槽位 | 理由 |
|------|------|------|
| `accent` / `mdCode` / `mdListBullet` | ANSI **4** | pi 自带主题里这三个角色绑定同一个 var（`"mdCode": "accent"`），所以给同一个槽。取 4 是为了跟 `render.sh` 的 `accent = blue` 以及 Polybar/Rofi/GTK 的强调色一致 |
| `border` / `borderAccent` / `borderMuted` | 4 / **6** / 8 | 三者得互不相同才有「普通 / 聚焦 / 失活」的层次；`borderAccent` 取 6（cyan）是照 pi 自带 `dark.json` 的 `borderAccent: cyan` |

**已知取舍**：`flat.json` 里 ANSI 8 承担了 19 个角色（`muted` / `dim` / `toolOutput` / `syntaxComment` / `borderMuted` / 滚动条…），而 ANSI 8 在各主题上是 1.57:1（oxocarbon）到 4.69:1（vesper）的暗灰——也就是说这些角色在 nord（1.69）和 oxocarbon（1.57）上几乎看不见。另有 10 个角色是 `""`（透明），消息条与工具框没有底色。这两点是「只用 ANSI 索引」的固有代价；要面板底色就得像 Omarchy 那样加模板生成 hex 主题（`default/themed/pi.json.tpl` → `omarchy-system`），代价是 pi 不再随终端调色板走，且要往 `config/pi/themes/` 写产物（那目录是软链到仓库的，得配 `.gitignore`）。

### 使用固定配色的应用（不纳入主题管理）

| 应用 | 配色 | 说明 |
|------|------|------|
| Vim | nord-vim | 硬编码 nord 配色，不跟随终端切换。`vimrc:50` 的 `colorscheme nord` 是我们的行（插件更新不会重置它），但要跟随主题得换成终端色 colorscheme，不是改一个值 |
| TMUX | nord-tmux | 同上，`tmux.conf:7` 的 `@plugin nord-tmux`。要跟随得去掉插件、用 `colour0-15` 自己写 `status-style` |
| zsh 提示符 | p10k | `~/.config/zsh/.p10k.zsh` 里 102 个 `*_FOREGROUND` 用的是 **256 色索引**（242/31/76/178/70/160/101…），而 **16-255 不受终端调色板影响** —— 提示符因此是目前唯一完全不跟随主题的可见元素（8 张 preview.jpg 里提示符一模一样）。**刻意不入仓**：该文件是 `p10k configure` 向导生成的，入仓后重跑向导会写穿 symlink 改到仓库（虽然 `git diff` 能发现、`git checkout` 能拿回）。想让它跟随又不想动 `.p10k.zsh`，可以在 `zshrc:115` 后面再加一句 source 一个自管的小 override 文件（p10k 的配色变量是渲染时读的，第一个提示符渲染前 source 完就生效）。见 [维护者笔记](maintenance.md) |

## 目录结构

```
themes/
├── colors/                    # 主题颜色定义
│   └── <theme-name>/
│       └── colors.toml
└── templates/                 # 模板文件
    ├── alacritty.toml.tpl
    ├── ghostty.conf.tpl
    └── <app>.tpl
```

渲染逻辑由 `settings/lib/render.sh`（函数库）提供；切换实现见 `settings/setting-theme.sh`。渲染产物位于 `~/.config/<app>/colors.*`，由脚本生成、不纳入版本控制（见 [维护者笔记](maintenance.md#版本控制)）。

## 主题列表

| 主题 | 色调 | 底色 h/s | fg/bg 对比 | 色值来源（上游官方配置） |
|------|------|----------|-----------|--------------------------|
| catppuccin-mocha | 冷紫蓝粉彩 | 240° / 21% | 11.3 | `catppuccin/alacritty` |
| tokyo-night | 深蓝紫 | 235° / 19% | 10.6 | `folke/tokyonight.nvim`（night） |
| kanagawa | 日式蓝调 | 240° / 13% | 11.3 | `rebelot/kanagawa.nvim`（wave） |
| nord | 冷低饱和 | 220° / 16% | 9.3 | `nordtheme/alacritty` |
| gruvbox | 暖中性灰 | 0° / 0% | 8.2 | `sainnhe/gruvbox-material`（dark medium） |
| Oxocarbon | 纯中性灰 | 0° / 0% | 18.1 | `nyoom-engineering/oxocarbon-alacritty` |
| dracula | 高饱和霓虹 | 231° / 15% | 13.4 | `dracula/alacritty` |
| vesper | 高对比极简 | 0° / 0% | 19.0 | `raunofreiberg/vesper` + `iTerm2-Color-Schemes` |

主题通过扫描 `themes/colors/` 子目录自动发现，新增目录即可识别。

没有任何一套 16 色方案能让全部 16 槽都 ≥4.5:1——`black`/`bright_black` 按设计就该贴合背景。
质量线定在「**fg/bg ≥ 7:1 且 6 个彩色槽全部 ≥ 4.5:1**」：上表 8 套里只有 **nord（3.05）和
kanagawa（3.22）不达标**，卡在红色槽（`#bf616a` / `#c34043`），而这正是两家的官方值。
这两种主题按上游原样保留，不在本地改色——改了就与上游不同步了。

## 使用方法

```bash
settings                       # 设置菜单（默认 TUI/fzf）
settings --gui                 # GUI（rofi；不可用时自动回退 TUI）
~/.local/share/dotfiles/settings/setting-theme.sh <主题名>   # 直接切换（单次）
```

渲染流程：`themes/render.conf`（声明）+ `themes/templates/<app>.tpl` + `themes/colors/<theme>/colors.toml` → `setting-theme.sh` → `~/.config/<app>/`

- `themes/render.conf` 每行声明一个目标：`应用|模板文件|输出路径|重载命令|标记`。**有模板文件不代表一定渲染，以声明为准**。
- 未装的应用默认跳过（`command -v`）；`标记` 含 `always` 的（GTK）始终渲染。无任何可渲染目标时报错退出。
- 套用逻辑就在 `setting-theme.sh` 内（它没有非 UI 复用方，不单独抽库）。

## colors.toml 格式

**只写「事实」，不写派生值。** colors.toml 里出现的每个色值都必须能在上游官方配置里找到，
共 20 个键：4 个基础 + 16 个 ANSI 槽。UI 专用色（暗底、次要文字、accent 等）由 `render.sh`
按公式算——手工填这些「角色」正是以前出错的原因（曾把 everforest 的背景色 `#4f585e` 填进
`dark_foreground`，落到 dunst 低优先级通知上只有 1.72:1，基本看不见）。

以 nord 为例（完整定义见 `themes/colors/nord/colors.toml`）：

```toml
mode = "dark"

background           = "#2e3440"
foreground           = "#d8dee9"
selection_background = "#4c566a"
selection_foreground = "#d8dee9"

# ANSI 16 色（顺序固定：0-7 normal，8-15 bright）
black        = "#3b4252"   # 0 black
red          = "#bf616a"   # 1 red
# ... green/yellow/blue/magenta/cyan/white
bright_black = "#4c566a"   # 8 bright black
# ... bright_red ... bright_white
```

文件头必须写明色值来源（上游仓库 + 文件路径），便于日后同步。

### 派生变量

`settings/lib/render.sh` 的 `RENDER_DERIVED` 声明派生规则，`colors.toml` 里已声明的同名键优先。
三种表达式：`@<键>`（直接取另一个键）、`scale:<键>:<百分比>`（RGB 等比缩放，保色相）、
`mix:<键A>:<键B>:<百分比>`（从 A 向 B 混合，百分比指 B 的权重）。

| 派生变量 | 规则 | 用途 |
|----------|------|------|
| `dark_background` | `scale(background, 80%)` | Polybar/Rofi 次层底色 |
| `darker_background` | `scale(background, 57%)` | 更深一档 |
| `lighter_background` | `scale(background, 130%)` | hover / 选中行 |
| `dark_foreground` | `mix(foreground, background, 42%)` | 次要文字（实测 3.8-6.9:1） |
| `light_foreground` | `mix(foreground, #ffffff, 30%)` | 亮文字 |
| `muted` | `mix(bright_black, foreground, 25%)` | GUI 禁用态（实测 2.8-7.1:1） |
| `accent` | `@blue` | 强调色 |
| `orange` | `mix(red, yellow, 50%)` | Polybar/Rofi 橙色 |
| `selection` | `@selection_background` | 兼容直接引用 `selection` 的模板 |

缩放系数（80/57/130）是按主流主题自带的层级色反推的：`scale(background, 80%)` 在 Catppuccin
上正好得到它官方的 `mantle`、57% 得到 `crust`。`orange = mix(red, yellow, 50%)` 与 Omarchy
全部 6 个可对照的 Omarchy 主题的 `orange` 实测 dE00 < 0.5，说明这是通行做法而非巧合。

**`muted` 不等于 ANSI 8。** 模板里 ANSI 8 槽直接写 `{{ bright_black }}`；`muted` 只服务于
GTK `insensitive_fg_color` 等 GUI 禁用态，所以向 `foreground` 提了 25% 以保证读得出来。

### 模板变量

- `{{ <键> }}` 替换为 `#rrggbb`（如 `{{ background }}` → `#2e3440`）
- `{{ <键>_strip }}` 去掉 `#`（用于 `0x`/裸十六进制）

模板引用了 colors.toml 和派生规则都没提供的变量时，`render` 会报错并列出变量名，
不会把字面的 `{{ foo }}` 静默写进应用配置。

### 已知偏离

- `gruvbox` 目录里的色值是 **Gruvbox Material**（`sainnhe/gruvbox-material`）而非原版
  `morhetz/gruvbox`：原版有 6 个 ANSI 槽低于 4.5:1（最低 2.69），Material 是它的降对比修正版。
- `vesper` 上游只有 3 个彩色（橙 `#ffc799` / 薄荷 `#99ffe4` / 红 `#ff8080`），16 个 ANSI 槽
  取自 iTerm2-Color-Schemes 的移植，其中 cyan 槽实际是粉色——上游没有青绿色。

## 模板里的硬约束

- **dunst 模板的颜色值必须加引号**（`foreground = "#ffffff"`）：裸 `#` 会被 dunst 当注释，整行失效。
- **fcitx5 的主题名固定为 `dotfiles`**：`classicui.conf` 里 `Theme=dotfiles` 只需一次性设置，模板不负责改它。
- **yazi 的 `[mode]` / `[tabs]` 必须同时给 fg 和 bg**：只给 bg 时终端默认前景会压在饱和底色上（实测对比度掉到 1.06-2.40）。当前取 `darkgray` 与 `color0 on color4` 是为了在 8 个主题下都过线；改这两个槽位前先按主题重测。
- **终端类应用的配色按对比度选槽位**（正文 WCAG 4.5:1 为线）：`muttrc` 就是拿 8 个主题逐一实测选的——ANSI 8 当正文不达标，故 `index_number` / `signature` / `tilde` 改用 color6 / color4。改主题时要重新对照，别按"看着顺眼"改。

## 支持的应用

声明见 `themes/render.conf`（每行 `应用|模板|输出|重载|标记`）：

| 应用 | 模板 | 输出 | 重载 |
|------|------|------|------|
| Alacritty | `alacritty.toml.tpl` | `alacritty/colors.toml` | 新窗口自动读取 |
| Ghostty | `ghostty.conf.tpl` | `ghostty/colors.conf` | `pkill -USR2 -x ghostty` |
| URxvt | `rxvt.tpl` | `X11/Xresources.d/rxvt-colors` | `xrdb -merge` |
| Polybar | `polybar.ini.tpl` | `polybar/colors.ini` | 随 `bspc wm -r` 重启 |
| Dunst | `dunst.conf.tpl` | `dunst/dunstrc.d/colors.conf` | `dunstctl reload` |
| Rofi | `rofi.rasi.tpl` | `rofi/colors.rasi` | 下次启动生效 |
| Zathura | `zathura.conf.tpl` | `zathura/colors.conf` | 重启 |
| BSPWM | `bspwm.sh.tpl` | `bspwm/colors.sh` | `bspc wm -r` |
| btop（主题） | `btop.theme.tpl` | `btop/themes/dotfiles.theme` | 重启 btop |
| btop（布局） | `btop.conf.tpl` | `btop/btop.conf` | 重启 btop（btop 退出时会回写该文件，模板才是真源） |
| fcitx5 | `fcitx5.conf.tpl` | `fcitx5/themes/dotfiles/theme.conf`（`data:` 前缀，落 `XDG_DATA_HOME`） | `fcitx5 -r -d`（必须重启：DBus `ReloadAddonConfig classicui` 虽能重读 `theme.conf`，但候选窗不重绘，实测无效） |
| GTK3 / GTK4 | `gtk3.css.tpl` / `gtk4.css.tpl` | `gtk-3.0/gtk.css` / `gtk-4.0/gtk.css` | 应用重启（标记 `always`，始终渲染） |

> btop 的两行没有 `always` 标记：未装 btop 的机器切主题不会生成 `~/.config/btop/`，事后装了要再切一次主题才有配色。
> btop 退出时会整份回写 `btop.conf`（值保留、注释被替换成它自己的），改设置请改模板。

> fcitx5 主题名固定为 `dotfiles`，换肤只重写 `theme.conf`，故 `classicui.conf`（已由 dotbot 纳管）里的 `Theme=dotfiles` 只需写一次，不随换肤改变。

## 添加新主题

```bash
mkdir -p themes/colors/my-theme
# 1. 从上游官方配置抄 20 个色值填进 colors.toml，文件头写明来源
# 2. 验证渲染（每个主题 × 每个模板全跑一遍，有未定义变量会报错）
for t in themes/colors/*/; do
  for tpl in themes/templates/*.tpl; do
    bash -c 'source settings/lib/render.sh; render "$0/colors.toml" "$1" /dev/null' "$t" "$tpl"
  done
done
# 3. 套用
~/.local/share/dotfiles/settings/setting-theme.sh my-theme
# 4. 截图（可选，供设置菜单预览）。capture.sh 默认不换主题，要先套用再截；
#    --all 会自己批量跑缺图的主题，不用手写循环
cd ~/.local/share/dotfiles/themes
./capture.sh colors/my-theme/preview.jpg   # 单张（当前主题）
./capture.sh --all                         # 批量补缺图，结束恢复原主题
```

新增前先算一下与现有主题的差异度：逐槽位对齐的 CIEDE2000 均值 < 10 就说明肉眼分不出来，
同一个「炎冷基调」的主题没必要收两个。

> `.gitignore` 用 `desktop/*/colors.*` 忽略产物（不用 `**/colors.*`——那会连主题源文件 `themes/colors/<theme>/colors.toml` 一起误伤，曾导致六个主题丢失）。产物落在 `desktop/<app>/` 下即自动覆盖。见 [ADR-0001](adr/0001-gitignore-colors-artifacts.md)。

## 添加新应用

1. 创建 `themes/templates/<app>.tpl`
2. 在 `themes/render.conf` 加一行 `应用|模板|输出路径|重载命令|标记`（输出路径默认相对 `XDG_CONFIG_HOME`，前缀 `data:` 表示相对 `XDG_DATA_HOME`；标记加 `always` 表示不判是否安装、始终渲染）
3. 需要重载才填第 4 列，不需要则留空

## 其它软件（评估结论）

评估过、**暂不接入**（不是不能，是收益太低或机制不可靠）：

- **Chromium 系浏览器（Edge / Chrome / Chromium）**
  - 主题 = 一个"主题扩展"（`manifest.json` 的 `theme` 段），格式全 Chromium 通用；但**装载麻烦**（`load-unpacked` 手动 / `--load-extension` 已被 Chrome 移除）。
  - 纯配置路：策略 `BrowserThemeColor`（写 `/{etc/opt/chrome,etc/chromium}/policies/managed/*.json`）——**Chrome/Chromium 支持且热加载**；**Edge 不支持**（实测 `edge://policy` 报"未知策略"）。
  - Edge 另有 `--install-autogenerated-theme="r,g,b"` 启动开关，或改 profile 的 `browser.theme.user_color2`——但**非即时**（要关闭/重启浏览器）。
  - **没有**改主题的 URI 协议。
  - 以上都只能给**单色**（其余由浏览器派生），非完整调色板。
- **Qt 应用**
  - 可定制：`qt5ct`/`qt6ct` 配色方案，或 `QT_QPA_PLATFORMTHEME=gtk3` + `qt6-gtk-platformtheme` 让它跟随 GTK 配色。
  - 但本机没装相关插件，且唯一 Qt 应用（微信）自带 QSS、不跟随系统调色板——收益极小。
- **VS Code / VSCodium / Cursor**
  - 主题本质是**扩展**：要么映射到已发布的 VS Code 主题扩展（Omarchy 的做法：`{name, extension}` + `code --install-extension` + 改 `workbench.colorTheme`），要么从 `colors.toml` 生成 `workbench.colorCustomizations` + `editor.tokenColorCustomizations` 写进 `settings.json`（纯配置、不装扩展，但要处理 JSONC 合并、覆盖项多）。
  - **暂缓**（不再装扩展是倾向；纯配置方案工作量大）。
