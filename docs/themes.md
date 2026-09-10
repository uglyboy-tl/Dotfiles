# 主题系统

## 概述

自研主题渲染系统：`colors.toml`（颜色定义）+ `.tpl`（模板）→ 各应用配置。

## 颜色策略

| 层次 | 应用类型 | 颜色来源 | 是否需要模板 |
|------|----------|----------|--------------|
| 源头 | 终端模拟器（Alacritty/Ghostty/URxvt） | 定义 16 色映射 | 需要 |
| 跟随 | CLI 工具（bat/zsh/neomutt/fastfetch 等） | 继承终端 16 色 | 不需要 |
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
│       └── colors.toml        # 颜色变量定义
└── templates/                 # 模板文件
    ├── alacritty.toml.tpl
    ├── ghostty.conf.tpl
    └── <app>.tpl
```

渲染逻辑由 `scripts/common/render.sh`（函数库）提供；切换入口是 `settings` 菜单，实现见 `scripts/common/setting-theme.sh`。

## 主题列表

| 主题 | 色调 |
|------|------|
| catppuccin-mocha | 紫/蓝 |
| nord | 北极蓝 |
| gruvbox | 复古暖色 |
| tokyo-night | 深蓝紫 |
| everforest | 绿色自然 |
| kanagawa | 日式蓝调 |

## 使用方法

```bash
settings                       # 设置菜单（默认 TUI/fzf）
settings --gui                 # GUI（rofi；不可用时自动回退 TUI）
setting-theme.sh <主题名>      # 直接切换指定主题
```

渲染流程：`themes/colors/<theme>/colors.toml` → `scripts/common/render.sh` → `~/.config/<app>/`

## colors.toml 格式

```toml
background = "#2E3440"
foreground = "#D8DEE9"
accent = "#88C0D0"
red = "#BF616A"
# ... 完整颜色定义见 themes/colors/nord/colors.toml
```

模板变量：`{{ background }}`（直接替换）、`{{ background_strip }}`（去 `#`）
派生变量：`selection_background`（从 `selection`）、`selection_foreground`（从 `bright_foreground`）

## 支持的应用

| 应用 | 模板 | 输出 | 重载 |
|------|------|------|------|
| Alacritty | `alacritty.toml.tpl` | `alacritty/colors.toml` | 自动 |
| Ghostty | `ghostty.conf.tpl` | `ghostty/colors.conf` | `SIGUSR2` |
| URxvt | `rxvt.tpl` | `X11/Xresources.d/rxvt-colors` | `xrdb -merge` |
| Polybar | `polybar.ini.tpl` | `polybar/colors.ini` | `polybar-msg cmd restart` |
| Dunst | `dunst.conf.tpl` | `dunst/dunstrc.d/colors.conf` | `dunstctl reload` |
| Rofi | `rofi.rasi.tpl` | `rofi/colors.rasi` | - |
| Zathura | `zathura.conf.tpl` | `zathura/colors.conf` | 重启 |
| BSPWM | `bspwm.sh.tpl` | `bspwm/colors.sh` | `bspc wm -r` |

### 待添加

- opencode / pi agent - 待检查是否支持主题配置
- vscode - 参考 Omarchy 的 `vscode-theme.json.tpl`

## 添加新主题

```bash
mkdir -p themes/colors/my-theme
# 创建 colors.toml 后运行
setting-theme.sh my-theme
```

## 添加新应用

1. 创建 `themes/templates/<app>.tpl`
2. 在 `scripts/common/setting-theme.sh` 的 `THEME_TEMPLATES` 添加映射
3. 如需重载，在 `RELOAD_CMDS` 添加命令
