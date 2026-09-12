# 设置菜单（Settings）

## 概述

统一入口，管理桌面可切换设置：**主题 / 壁纸 / 字体 / 快捷键**。同一套代码提供两种界面：

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
├── settings                         # 入口：解析 --gui → SELECTOR_UI，菜单循环
├── selectors.sh                     # 选择器：select_ui / selector_gui_supported / epipe_init
├── notify.sh                        # 消息：notify / notify_error
├── render.sh                        # 模板渲染（主题脚本使用）
├── setting-theme.sh                 # 主题切换
├── setting-wallpaper.sh             # 壁纸切换
├── setting-font.sh                  # 字体切换
├── setting-keybindings.sh           # 快捷键速查（只读）
├── img-preview.py / font-sample.sh / wallpaper-image.sh / sxhkd-shortcuts.py  # 预览与解析 helper
└── LICENSE.kittytgp                 # img-preview.py 的第三方许可
```

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
