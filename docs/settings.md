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
scripts/
├── settings                         # 入口：解析 --gui → SELECTOR_UI，菜单循环
└── common/
    ├── selectors.sh                 # 选择器：select_ui / selector_gui_supported / epipe_init
    ├── notify.sh                    # 消息：notify / notify_error
    ├── setting-theme.sh             # 主题切换
    ├── setting-wallpaper.sh         # 壁纸切换
    ├── setting-font.sh              # 字体切换
    └── setting-keybindings.sh       # 快捷键速查
```

## 界面分派

`SELECTOR_UI`（gui/tui，默认 tui）是唯一的界面判定，只在入口解析一次并导出：

- `settings --gui` 时调用 `selector_gui_supported()` 校验（rofi 可用 **且** 有图形会话），不满足则回退 tui 并在日志提示
- 子脚本继承环境变量，不再接收 `--gui`
- 组件调用 `select_ui -p <提示> -d <数据> [-s <当前>]` 即可，不感知 rofi/fzf

## 新增设置项

在 `scripts/common/` 新建 `setting-<name>.sh`，按四函数模板：

```bash
source "$DOTFILES_DIR/scripts/common/selectors.sh"
source "$DOTFILES_DIR/scripts/common/notify.sh"
epipe_init

select_<name>() {                    # 选择（用户取消 → 退出）
  X=$(select_ui -p "..." -d "$(get_items)") || exit 0
}

validate_<name>() { ...; return 1 }  # 校验失败返回 1，不退出进程

apply_<name>() {                     # 应用（校验失败返回非零）
  validate_<name> "$X" || return 1
  # ... 生效逻辑 ...
  notify "已切换$name: $X"
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

然后注册进 `scripts/settings` 的 `get_settings_items` 与 `case`。

## 语义约定

| 场景 | 行为 |
|------|------|
| 用户取消选择 | `exit 0`（整个设置项退出） |
| 非法输入 | `validate` 返回 1 → 提示"已忽略"，回到选择界面 |
| 致命错误（如主题无可用模板） | `exit 1` |

消息一律走 `notify` / `notify_error`：GUI 下桌面通知，不可用或命令行下回退输出（`notify.py` 见 `scripts/common/notify.sh`）。

## 已知坑

- **sxhkd 启动 EPIPE**：快捷键启动时 stdout 是 socket，`echo` 会触发 SIGPIPE 中断脚本（`set -e` 下直接退出）。`epipe_init()` 忽略 SIGPIPE，且非 tty 时把输出重定向到 `~/.local/state/settings/logs/<脚本名>.log`。
- **bspwm 重载吞通知**：`bspc wm -r` 会重跑 bspwmrc，其中 `_s dunst` 会重启 dunst，导致刚发的通知被吞。主题切换因此先重载各软件、等新 dunst 就绪（`wait_dunst_ready`）再 `notify`。