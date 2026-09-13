# 主题系统

## 概述

自研主题渲染系统：`colors.toml`（颜色定义）+ `.tpl`（模板）→ 各应用配置。切换入口是 [设置菜单](settings.md)，当前主题记录在 `~/.local/state/theme/current`。

## 颜色策略

| 层次 | 应用类型 | 颜色来源 | 是否需要模板 |
|------|----------|----------|--------------|
| 源头 | 终端模拟器（Alacritty/Ghostty/URxvt） | 定义 16 色映射 | 需要 |
| 跟随 | CLI/TUI 工具（bat/zsh/neomutt/fastfetch/herdr 等） | 继承终端 16 色 | 不需要 |
| 独立 | GUI 应用（Polybar/Rofi/Dunst/Zathura） | 独立颜色系统 | 需要 |

CLI 工具跟随终端的好处：一次切换全局生效，维护成本低。

### 使用固定配色的应用（不纳入主题管理）

| 应用 | 配色 | 说明 |
|------|------|------|
| Vim | nord-vim | 硬编码 nord 配色，不跟随终端切换 |
| TMUX | nord-tmux | 硬编码 nord 配色，不跟随终端切换 |

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

| 主题 | 色调 |
|------|------|
| catppuccin-mocha | 紫/蓝 |
| nord | 北极蓝 |
| gruvbox | 复古暖色 |
| tokyo-night | 深蓝紫 |
| everforest | 绿色自然 |
| kanagawa | 日式蓝调 |

主题通过扫描 `themes/colors/` 子目录自动发现，新增目录即可识别。

## 使用方法

```bash
settings                       # 设置菜单（默认 TUI/fzf）
settings --gui                 # GUI（rofi；不可用时自动回退 TUI）
~/.local/share/dotfiles/settings/setting-theme.sh <主题名>   # 直接切换（单次）
```

渲染流程：`themes/colors/<theme>/colors.toml` → `settings/lib/render.sh` → `~/.config/<app>/`

仅渲染已安装（`command -v`）的应用；无任何可用模板时报错退出。

## colors.toml 格式

以 nord 为例（完整定义见 `themes/colors/nord/colors.toml`）：

```toml
mode = "dark"

background = "#2e3440"
dark_background = "#3b4252"
darker_background = "#434c5e"
lighter_background = "#4c566a"

foreground = "#8fbcbb"
dark_foreground = "#88c0d0"
light_foreground = "#81a1c1"
bright_foreground = "#eceff4"

accent = "#8fbcbb"
selection = "#5e81ac"
muted = "#4c566a"

red = "#bf616a"
green = "#a3be8c"
# ... yellow/blue/magenta/cyan/orange/brown 及 bright_* 变体
```

模板变量：

- `{{ background }}` 直接替换为 `#2e3440`
- `{{ background_strip }}` 去掉 `#`（用于生成 `0x`/裸十六进制）

派生变量（由 `render.sh` 的 `RENDER_DERIVED_VARS` 计算）：

- `selection_background` ← `selection`
- `selection_foreground` ← `bright_foreground`

## 支持的应用

映射表见 `setting-theme.sh` 的 `THEME_TEMPLATES` / `RELOAD_CMDS`：

| 应用 | 模板 | 输出 | 重载 |
|------|------|------|------|
| Alacritty | `alacritty.toml.tpl` | `alacritty/colors.toml` | 新窗口自动读取 |
| Ghostty | `ghostty.conf.tpl` | `ghostty/colors.conf` | `pkill -USR2 -x ghostty` |
| URxvt | `rxvt.tpl` | `X11/Xresources.d/rxvt-colors` | `xrdb -merge` |
| Polybar | `polybar.ini.tpl` | `polybar/colors.ini` | `polybar-msg cmd restart` |
| Dunst | `dunst.conf.tpl` | `dunst/dunstrc.d/colors.conf` | `dunstctl reload` |
| Rofi | `rofi.rasi.tpl` | `rofi/colors.rasi` | 下次启动生效 |
| Zathura | `zathura.conf.tpl` | `zathura/colors.conf` | 重启 |
| BSPWM | `bspwm.sh.tpl` | `bspwm/colors.sh` | `bspc wm -r` |

## 添加新主题

```bash
mkdir -p themes/colors/my-theme
# 创建 colors.toml 后运行
~/.local/share/dotfiles/settings/setting-theme.sh my-theme
```

> 注意 `.gitignore` 的 `**/colors.*` 会误伤主题源文件，提交前确认它被纳入版本控制，见 [维护者笔记](maintenance.md#版本控制)。

## 添加新应用

1. 创建 `themes/templates/<app>.tpl`
2. 在 `settings/setting-theme.sh` 的 `THEME_TEMPLATES` 添加映射 `"应用:模板:输出路径"`
3. 如需重载，在 `RELOAD_CMDS` 添加命令
