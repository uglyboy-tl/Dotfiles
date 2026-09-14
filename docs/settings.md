# 设置菜单（Settings）

## 概述

统一入口，管理桌面可切换设置与查看类条目：**主题 / 壁纸 / 字体 / 开关 / 快捷键 / 关于**。同一套代码提供两种界面：

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
├── setting-toggles.sh               # 布尔开关子菜单（纯 UI，具体开关见 toggles/）
├── setting-keybindings.sh           # 快捷键速查（条目式，选中即执行）
├── setting-about.sh                 # 关于（fastfetch 系统信息，经 show 层双端展示）
├── toggles/                         # 布尔开关实现（每个开关一个独立脚本）
│   ├── polybar-shadow.sh            #   Polybar 阴影
│   └── dunst-pause.sh               #   免打扰（暂停通知）
├── rofi/                            # 设置 rofi 主题
│   ├── settings.rasi                # 主菜单
│   ├── preview.rasi                 # 带图片预览的选择界面
│   └── viewer.rasi                  # 只读内容查看窗（show_gui 使用）
└── lib/                             # 库与 helper
    ├── selectors.sh                 # 选择器：select_ui / selector_gui_supported / epipe_init
    ├── toggles.sh                    # 布尔开关引擎（发现 + 状态 + apply_all）
    ├── wallpaper.sh                  # 壁纸引擎（风格 / 状态 / dwall / crontab；bspwmrc 也用）
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

## 开关（布尔设置）

布尔型设置分三层，各层互不了解对方细节：

- **菜单 UI** `setting-toggles.sh`：只调引擎的 `toggles_keys / toggle_label / toggle_state / toggle_flip`，列出「标签：开/关」、**选中即翻转并 `notify` 提示**；走 `select_ui`，复用设置主题（`settings/rofi/settings.rasi`），**无需单独新建 rasi**，也不含任何具体功能。
- **引擎** `lib/toggles.sh`（通用，可 source）：发现开关、读写状态、`toggles_apply_all`。状态存于 `$XDG_STATE_HOME/settings/toggles/<key>`（`1`/`0`，不进版本库）；无状态文件时用该开关脚本给的默认值。
- **具体开关** `toggles/<key>.sh`：每个开关一个独立可执行脚本。

**新增开关 = 往 `settings/toggles/` 丢一个可执行脚本**，不碰菜单、不碰引擎。脚本约定三个子命令：

| 子命令 | 作用 |
|--------|------|
| `label` | 打印显示名 |
| `default` | 打印"未选择时"的默认状态（`0`/`1`；缺省视为 `1`） |
| `apply <0\|1> [settle]` | 按给定状态套用（`settle` 非空时用于骑过窗口重建，可忽略） |

提示统一由菜单发出（`notify`，套用后）；开关脚本只负责套用，不涉及提示。

**启动套用**：`bspwmrc` 在 `_s polybar` 之后直接 source 引擎并调 `toggles_apply_all settle`，**不经过菜单 UI**——所以启动/重载只重套、不弹任何提示。

**已有开关**

| 开关 | 实现 | 默认 |
|------|------|------|
| Polybar 阴影 | 用 picom 的窗口属性 `_COMPTON_SHADOW` **实时**开关：关闭时给 polybar 窗口设 `_COMPTON_SHADOW=0`，开启时移除该属性恢复默认。**不改任何配置文件、不重启 picom**（picom 会监听该属性变化重算阴影）。 | 关（无阴影） |
| 免打扰 | `dunstctl set-paused` 暂停/恢复通知。关闭时**先 `close-all` 丢弃暂停期间积压的通知再恢复**（否则恢复瞬间会一次性弹出旧通知）。开启时的提示会被暂停的 dunst 排队、看不到，并在下次关闭时随积压一起清掉，属正常。 | 关（正常通知） |

> `_COMPTON_SHADOW` 是会话内属性，polybar 窗口重建后会丢失，且重建期间新旧窗口会短暂并存。故该开关的 `apply` 在 `settle` 模式下于数秒内反复设到当前所有 polybar 窗口上，骑过整个重建（只设一次会落到正在退出的旧窗口上而落空）；交互式翻转只设一次。

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

> **何时抽引擎库**：仅当套用逻辑需要在**非 UI** 场景复用才抽到 `lib/`，否则就近放在设置脚本里。
> 例：`setting-wallpaper` 的套用被 `bspwmrc` 直接调用，故引擎在 `lib/wallpaper.sh`（菜单脚本变薄）；
> `setting-theme` / `setting-font` 没有非 UI 调用方，套用逻辑就在各自脚本内（不单独抽库）。
> `setting-font.sh` 另有 `apply_font` / `apply_font_run` 的小拆分（纯生效 / 带校验+通知）。

## 状态文件

主题、壁纸脚本把当前值写入 `~/.local/state/<name>/current`，用于在菜单里高亮当前项：

| 脚本 | 状态文件 |
|------|----------|
| 主题 | `~/.local/state/theme/current` |
| 壁纸 | `~/.local/state/wallpaper/current` |
| 开关（布尔设置） | `~/.local/state/settings/toggles/<key>`（每个开关一个文件，`1`/`0`） |

## 语义约定

| 场景 | 行为 |
|------|------|
| 用户取消选择 | `exit 0`（整个设置项退出） |
| 非法输入 | `validate` 返回 1 → 提示"已忽略"，回到选择界面 |
| 致命错误（如主题无可用模板） | `exit 1` |

消息一律走 `notify` / `notify_error`：GUI 下桌面通知，不可用或命令行下回退输出。
