# 设置菜单（Settings）

## 概述

统一入口，管理桌面可切换设置与查看类条目：**主题 / 壁纸 / 字体 / 快捷键 / 关于**。同一套代码提供两种界面：

| 界面 | 工具 | 启用方式 |
|------|------|----------|
| TUI | fzf | 命令行直接运行（默认） |
| GUI | rofi | `--gui` 参数或桌面快捷键 |

## 使用

```bash
settings            # TUI（fzf）
settings --gui      # GUI（rofi）；rofi 不可用或无图形会话时自动回退 TUI 并提示
```

- 入口链接：`~/.local/bin/settings`
- 桌面快捷键：`Super + ;`（sxhkd 中为 `super + semicolon`，直接 `settings --gui`）

## 目录结构

```
settings/                              # 设置菜单（独立目录，入口链接到 ~/.local/bin/settings）
├── settings                         # 入口：解析 --gui → SELECTOR_UI，主菜单循环
├── setting-theme.sh                 # 主题切换
├── setting-wallpaper.sh             # 壁纸切换
├── setting-font.sh                  # 字体切换
├── setting-keybindings.sh           # 快捷键速查（条目式，选中即执行）
├── setting-about.sh                 # 关于（fastfetch 系统信息，经 show 层双端展示）
├── rofi/                            # 设置 rofi 主题
│   ├── settings.rasi                # 主菜单
│   ├── preview.rasi                 # 带图片预览的选择界面
│   └── viewer.rasi                  # 只读内容查看窗（show_gui 使用）
└── lib/                             # 库与 helper
    ├── selectors.sh                 # 选择器：select_ui / selector_gui_supported / epipe_init
    ├── menu.sh                       # 通用菜单循环 menu_loop + 退出整栈传播 MENU_EXIT_ALL
    ├── notify.sh                     # 消息：notify / notify_error
    ├── render.sh                     # 模板渲染（主题脚本使用）
    ├── show.sh                       # 内容展示层：show_content / show_terminal / show_gui
    ├── ansi_parse.py                 # ANSI 解析核心（共享）：光标模拟 + SGR
    ├── ansi-to-pango.py              # ANSI → Pango 转换器（rofi 展示用）
    ├── ansi-to-ansi.py               # ANSI → ANSI 转换器（fzf 预览用）
    ├── sxhkd-shortcuts.py            # sxhkdrc 解析（快捷键速查使用）
    ├── image_cache.py                # fzf 预览图缓存（img-preview 使用）
    ├── img-preview.py / font-sample.sh / wallpaper-image.sh  # 预览 helper
    └── LICENSE.kittytgp              # img-preview.py 的第三方许可
```

## 快捷键 / 关于

执行/查看类条目直接挂在主菜单下，没有额外层级：

| 条目 | 脚本 | 说明 |
|------|------|------|
| 快捷键 | `setting-keybindings.sh` | 列出精选快捷键，**选中即执行**对应命令；`Super + k` 直接打开（链接为 `~/.local/bin/keybindings`） |
| 关于 | `setting-about.sh` | 展示 fastfetch 彩色输出，经内容展示层（`show_content`）按界面双端呈现 |

快捷键界面执行命令后返回 `MENU_EXIT_ALL`，由入口菜单（`--root`）捕获后整体退出。这是通用约定：**任何菜单子项只要返回 `MENU_EXIT_ALL` 即可退出整个菜单栈**；左键/Esc 取消则正常返回上级。该脚本独立运行时默认用 rofi（无 `SELECTOR_UI` 继承时）。

## 内容展示层（show）

`lib/show.sh` 把「带 ANSI 颜色的命令输出」按界面统一呈现，是**展示类**功能的通用层：

| 函数 | 界面 | 实现 |
|------|------|------|
| `show_terminal <命令>` | TUI | fzf 预览窗格；`ansi-to-ansi.py` 把光标移动转为空格填充，保留颜色与对齐 |
| `show_gui <命令>` | GUI | rofi 只读窗（`settings/rofi/viewer.rasi`，`fixed-height: false` 按条目数自适应高度）；`ansi-to-pango.py` 转 Pango markup |
| `show_content <命令>` | 自动分派 | 按 `SELECTOR_UI` 选 `show_gui` 或 `show_terminal` |

约定：

- 传入**完整命令**（含 `--pipe false` 这类强制彩色输出的参数），展示层不假设输出工具
- 调色板取自当前主题 `themes/colors/<theme>/colors.toml`；GUI 字体从 `viewer.rasi` 读取，作为宽度测量的单一来源
- `--prompt <提示>` 可选；TUI 以 Esc/← 返回，GUI 以 Esc/← /→ 关闭

新增展示项只需一行：

```bash
show_content "fastfetch --pipe false" --prompt "关于"
```

转换器分工：`ansi_parse.py` 是共享核心（光标模拟、SGR），`ansi-to-ansi.py`（fzf）与 `ansi-to-pango.py`（rofi）是各自的薄输出层。

## 界面分派

`SELECTOR_UI`（gui/tui，默认 tui）是唯一的界面判定，只在入口解析一次并导出：

- `settings --gui` 时调用 `selector_gui_supported()` 校验（rofi 可用 **且** 有图形会话），不满足则回退 tui 并在日志提示
- 子脚本继承环境变量，不再接收 `--gui`
- 组件调用 `select_ui -p <提示> -d <数据> [-s <当前>]` 即可，不感知 rofi/fzf

## 新增设置项

在 `settings/` 新建 `setting-<name>.sh`，按 `setting-theme.sh` 的函数模板：

```bash
source "$DOTFILES_DIR/settings/lib/selectors.sh"
source "$DOTFILES_DIR/settings/lib/notify.sh"
epipe_init

select_<name>() {                    # 选择：调用 select_ui，用户取消 → exit 0
  X=$(select_ui -p "..." -d "$(get_items)" -s "$(get_current)") || exit 0
}

validate_<name>() { ...; return 1 }  # 校验失败返回 1，不退出进程

apply_<name>() {                     # 应用（校验失败返回非零）
  validate_<name> "$1" || return 1
  # ... 生效逻辑 ...
  notify "已切换$name: $1"
}

loop_mode() {                        # 循环：非法输入继续选择，取消才退出
  while true; do
    select_<name>
    apply_<name> "$X" || continue
  done
}

main() { [ $# -ge 1 ] && apply_<name> "$1" || loop_mode }
main "$@"
```

然后注册进 `settings/settings` 的 `get_settings_items` 与 `case`。

> 变体：`setting-font.sh` / `setting-wallpaper.sh` 拆成 `apply_<name>`（纯生效）与
> `apply_<name>_run`（校验+生效+通知），因为 `setting-wallpaper.sh` 会被 `bspwmrc` 直接调用。

## 状态文件

主题、壁纸脚本把当前值写入 `~/.local/state/<name>/current`，用于在菜单里高亮当前项：

| 脚本 | 状态文件 |
|------|----------|
| 主题 | `~/.local/state/theme/current` |
| 壁纸 | `~/.local/state/wallpaper/current` |

## 语义约定

| 场景 | 行为 |
|------|------|
| 用户取消选择 | `exit 0`（整个设置项退出） |
| 非法输入 | `validate` 返回 1 → 提示"已忽略"，回到选择界面 |
| 致命错误（如主题无可用模板） | `exit 1` |

消息一律走 `notify` / `notify_error`：GUI 下桌面通知，不可用或命令行下回退输出。
