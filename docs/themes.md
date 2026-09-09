# 主题系统

## 概述

本项目使用自研的主题渲染系统，通过统一的颜色定义文件（`colors.toml`）+ 模板文件（`.tpl`）生成各应用的颜色配置。灵感来源于 omarchy 的颜色管理方式。

核心思路：
1. 每个主题维护一个 `colors.toml`，定义所有颜色变量
2. 每个应用维护一个模板文件，使用 `{{ variable }}` 占位符
3. `render.sh` 读取颜色文件，通过 sed 替换模板中的占位符，生成最终配置

## 颜色策略

本项目的颜色管理分为两个层次：

### 1. 终端模拟器 - 定义 16 色映射

终端模拟器（Alacritty、Ghostty、URxvt）是颜色的「源头」。它们负责将 ANSI 16 色映射到具体的 hex 颜色值。这些应用需要模板文件。

当主题切换时，终端模拟器的 16 色映射会改变，所有运行在其中的 CLI 工具颜色自动跟随变化。

### 2. CLI 工具 - 遵循终端 16 色

CLI 工具不需要模板文件，它们直接使用终端的 16 色调色板。当终端模拟器的主题切换时，所有 CLI 工具的颜色自动跟随变化。

这种策略的好处：
- **一次切换，全局生效**：只需切换终端模拟器的主题，所有 CLI 工具自动跟随
- **减少维护成本**：CLI 工具无需单独维护模板
- **一致性**：整个终端环境颜色统一

#### 各工具的颜色配置

**Vim** - 使用 base16 兼容主题

```vim" colorscheme 使用 base16 系列，自动匹配终端 16 色
colorscheme base16-catppuccin-mocha
let g:lightline = {'colorscheme': '16color'}
```

base16 主题的设计理念就是将颜色决策交给终端，Vim 只是引用 color0-color15 的语义名称。

**TMUX** - 通过主题插件继承终端色

```bash
# 使用 nord-tmux 主题，它从终端 16 色读取颜色
set -g @plugin 'arcticicestudio/nord-tmux'
set-option -g default-terminal screen-256color
```
nord-tmux 会从终端的 ANSI 颜色中提取配色，而非硬编码 hex 值。

**Bat** - 自动使用终端主题

```bash
# bat/config
--theme="ansi"
```
`ansi` 主题让 bat 直接使用终端的 16 色，无需额外配置。

**Yazi** - 使用终端 16 色

```toml
# yazi/theme.toml
# Uses terminal 16-color palette - colors follow terminal theme automatically
[mgr]
cwd = { fg = "cyan" }
```
Yazi 的主题文件使用 `color1`-`color15` 和语义名称（如 `cyan`、`blue`），直接映射到终端调色板。

**LF 文件管理器** - 直接引用终端色号

```bash
# lf/lfrc
default  default
color status  color4  default
color dir    cyan    default
color exec   yellow  default
```
使用 `colorN` 语法直接引用终端的 ANSI 颜色编号。

**NeoMutt** - 使用终端 16 色索引

```bash
# mail/muttrc - 使用终端 16 色索引, 跟随终端主题
color normal          default default
color error           color1  default
color message         color4  default
color indicator       color0 color4
color index           color15 default
color header          color4  default "^From:"
color quoted0         color2  default
```
NeoMutt 使用 `colorN` 语法（N=0-15），直接引用终端调色板，无需维护独立主题。

**FZF** - 通过环境变量继承终端色

```bash
# zshrc.zsh
export FZF_DEFAULT_OPTS="\
--color=16,border:gray,label:gray \
--color=hl:blue,hl+:reverse:blue \
--color=pointer:cyan,spinner:cyan,marker:cyan \
--color=info:yellow,prompt:yellow \
--height 50% --preview-window right:60% --layout=reverse"
```
FZF 的 `--color=16` 表示使用终端的 16 色调色板，后续的 `hl:blue` 等是语义映射，指向 color4 等。

**Zsh/Starship** - 跟随终端色

```bash
# starship.toml
[character]
success_symbol = "[❯](bold cyan)"
error_symbol = "[✗](bold cyan)"

[directory]
repo_root_style = "bold cyan"

[git_branch]
style = "italic cyan"
```
Starship 使用 `cyan`、`blue` 等语义颜色名，直接映射到终端的 ANSI 色。

### 3. GUI 应用 - 独立配置

GUI 应用（Polybar、Rofi、Dunst、Zathura 等）有自己独立的颜色系统，需要模板文件。

### 分类总结

| 类型 | 颜色来源 | 是否需要模板 |
|------|----------|--------------|
| 终端模拟器（Alacritty/Ghostty/URxvt） | 定义 16 色映射 | 需要 |
| CLI 工具（bat/lf/yazi/vim/zsh/tmux） | 继承终端 16 色 | 不需要 |
| GUI 应用（Polybar/Rofi/Dunst/Zathura） | 独立颜色系统 | 需要 |
| 状态栏（Polybar） | 混合（部分继承终端色） | 需要 |

## 目录结构

```
themes/
├── colors/                    # 主题颜色定义（每个主题一个子目录）
│   └── <theme-name>/
│       └── colors.toml        # 颜色变量定义
├── templates/                 # 模板文件
│   ├── alacritty.toml.tpl     # Alacritty 终端
│   ├── ghostty.conf.tpl       # Ghostty 终端
│   ├── rxvt.tpl               # URxvt 终端
│   ├── polybar.ini.tpl        # Polybar 状态栏
│   ├── dunst.conf.tpl         # Dunst 通知
│   ├── rofi.rasi.tpl          # Rofi 启动器
│   └── zathura.conf.tpl       # Zathura PDF 阅读器
└── render.sh                  # 渲染脚本
```

## 使用方法

### 切换主题

```bash
# 使用 fzf 交互选择
theme

# 使用 rofi GUI 选择
theme --gui

# 直接切换到指定主题
theme <主题名>
```

脚本位于 `desktop/scripts/theme`，安装后自动链接到 `~/.local/bin/theme`。

### 渲染流程

1. 从 `themes/colors/<theme>/colors.toml` 读取颜色定义
2. 遍历 `themes/templates/` 下所有模板文件
3. 对每个已安装的应用，使用 `render.sh` 渲染对应模板
4. 输出到 `~/.config/<app>/` 下的颜色配置文件
5. 重载已运行的应用

### render.sh 用法

```bash
./themes/render.sh <colors.toml> <template.tpl> <output>
```

示例：
```bash
./themes/render.sh themes/colors/nord/colors.toml themes/templates/alacritty.toml.tpl ~/.config/alacritty/colors.toml
```

## colors.toml 格式

```toml
# 基础颜色
background = "#2E3440"
foreground = "#D8DEE9"
muted = "#4C566A"

# 语义颜色
accent = "#88C0D0"
selection = "#434C5E"

# ANSI 16 色
red = "#BF616A"
green = "#A3BE8C"
yellow = "#EBCB8B"
blue = "#81A1C1"
magenta = "#B48EAD"
cyan = "#88C0D0"

# 亮色变体
bright_red = "#BF616A"
bright_green = "#A3BE8C"
bright_yellow = "#EBCB8B"
bright_blue = "#81A1C1"
bright_magenta = "#B48EAD"
bright_cyan = "#8FBCBB"
bright_foreground = "#ECEFF4"

# 选择区（可选，不定义则从 selection 派生）
selection_background = "#434C5E"
selection_foreground = "#ECEFF4"
```

### 模板变量语法

| 语法 | 说明 |
|------|------|
| `{{ background }}` | 直接替换为 `#2E3440` |
| `{{ background_strip }}` | 去掉 `#`，替换为 `2E3440`（用于需要无井号值的场景） |
| `{{ selection_foreground }}` | 派生变量（若未定义，从 selection 派生） |

### 派生变量

以下变量在 `render.sh` 中自动派生，无需在 `colors.toml` 中重复定义：

| 派生变量 | 来源 |
|----------|------|
| `selection_background` | `selection` |
| `selection_foreground` | `bright_foreground` |

## 模板文件说明

### alacritty.toml.tpl

生成 `~/.config/alacritty/colors.toml`，被 `alacritty.toml` 通过 `import` 引入。

关键映射：
- `colors.primary.background/foreground`
- `colors.normal.*` - ANSI 正常色
- `colors.bright.*` - ANSI 亮色
- `colors.selection.*` - 选区颜色
- `colors.cursor.*` - 光标颜色

### ghostty.conf.tpl

生成 `~/.config/ghostty/colors.conf`，被 `config.ghostty` 通过 `theme` 指定。

关键映射：
- `background-color`, `foreground-color`
- `palette` - ANSI 16 色
- `selection-background`, `selection-foreground`
- `cursor-color`, `cursor-text`

### rxvt.tpl

生成 `~/.config/X11/Xresources.d/rxvt-colors`，被 `rxvt-unicode` 通过 `#include` 引入。

关键映射：
- `URxvt.background`, `URxvt.foreground`
- `URxvt.color0` ~ `URxvt.color15` - ANSI 16 色
- `URxvt.colorBD`, `URxvt.colorIT` - 粗体/斜体颜色

### polybar.ini.tpl

生成 `~/.config/polybar/colors.ini`，被 Polybar 配置通过 `include-modules` 引入。

关键映射：
- `background`, `foreground` - 基础色
- `accent`, `selection`, `muted` - 语义色
- `red`, `green`, `yellow` 等 - ANSI 色
- `trans`, `semi-trans` - 透明色（使用 strip 变量）

### dunst.conf.tpl

生成 `~/.config/dunst/dunstrc.d/colors.conf`，作为 drop-in 配置被 Dunst 自动加载。

关键映射：
- `frame_color` - 通知框边框色
- `background` - 通知背景色
- `foreground` - 通知文字色
- `highlight` - 强调色

### rofi.rasi.tpl

生成 `~/.config/rofi/colors.rasi`，被 Rofi 配置通过 `@import "colors"` 引入。

关键映射：
- `background`, `foreground` - 基础色
- `accent` - 强调色
- `dark-background`, `lighter-background` 等 - 层级背景色

### zathura.conf.tpl

生成 `~/.config/zathura/colors.conf`，被 `zathurarc` 通过 `#include colors.conf` 引入。

关键映射：
- `set default-fg`, `set default-bg` - 基础色
- `set highlight-color` - 搜索高亮色
- `set highlight-active-color` - 当前搜索高亮色

## 应用重载

主题切换后，脚本会自动重载以下应用：

| 应用 | 重载方式 |
|------|----------|
| Polybar | `polybar-msg cmd restart` |
| Dunst | `dunstctl reload` |
| Ghostty | `pkill -USR2 -x ghostty` |
| URxvt | `xrdb -merge ~/.config/X11/Xresources` |

Alacritty 和 Zathura 支持热重载，无需额外操作。

## 添加新主题

1. 在 `themes/colors/` 下创建新目录：
   ```bash
   mkdir -p themes/colors/my-theme
   ```

2. 创建 `colors.toml`，定义颜色变量：
   ```toml
   background = "#1E1E2E"
   foreground = "#CDD6F4"
   # ... 其他颜色
   ```

3. 运行主题切换脚本验证：
   ```bash
   theme my-theme
   ```

## 添加新应用支持

1. 在 `themes/templates/` 下创建模板文件 `<app>.tpl`
2. 在 `desktop/scripts/theme` 脚本的 `THEME_TEMPLATES` 映射中添加：
   ```bash
   ["app-name"]="app.tpl:app/colors.conf"
   ```
3. 如果需要自动重载，在 `RELOAD_CMDS` 映射中添加：
   ```bash
   ["app-name"]="reload-command"
   ```
