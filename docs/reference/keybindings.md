# 快捷键

常用操作速查。完整、权威的列表以 `desktop/bspwm/sxhkdrc` 为准，也可运行 `settings` → 「快捷键」交互查看。

## BSPWM / sxhkd

| 快捷键 | 操作 |
|--------|------|
| `Super + Return` | 终端（Ghostty） |
| `Super + r` | 应用启动器（rofi drun） |
| `Alt + Tab` | 窗口切换（rofi window） |
| `Super + e` | 文件管理器（yazi） |
| `Super + m` / `h` / `n` | 音乐 / 系统监控 / 新闻（ncmpcpp / btop / newsboat） |
| `Super + v` | 用 mpv 播放剪贴板 URL |
| `Super + b` | 蓝牙菜单 |
| `Super + ;` | 设置菜单 |
| `Super + k` | 快捷键执行菜单（选中即执行，仿 Omarchy） |
| `Super + w` / `Shift + w` | 关闭 / 强制关闭窗口 |
| `Super + t` / `Shift + t` / `s` / `f` | 平铺 / 伪平铺 / 浮动 / 全屏 |
| `Super + Space` | 浮动 ↔ 平铺 |
| `Super + Shift + f` | 切换布局 |
| `Super + {1-9,0}` | 聚焦桌面 1-10（配置了 6 个：I-VI） |
| `Super + Shift + {1-9,0}` | 把窗口移到桌面 |
| `Super + Alt + r` | 重载 BSPWM |
| `Super + Alt + q` | 退出 BSPWM |
| `Super + Escape` | 重启 sxhkd |

音量用多媒体键（经 `barify` 显示指示条）。亮度用多媒体键：台式机外接显示器走 `brightness`（DDC/CI，经 `ddcutil`），需要 `i2c-dev` 且用户在 `i2c` 组；DDC 单次往返有 ~300ms 硬件延迟，通知先本地即时反馈、调节在后台执行。

## TMUX

| 快捷键 | 操作 |
|--------|------|
| `Ctrl + a` | 前缀键 |
| `Ctrl + a` `d` | 脱离会话 |
| `Ctrl + a` `c` | 新窗口 |
| `Ctrl + a` `%` / `"` | 垂直 / 水平分屏 |

## Shell（别名与函数）

见 `config/zsh/aliases.zsh`：

| 命令 | 操作 |
|------|------|
| `size <dir>` | 统计目录大小（按大小排序） |
| `runv` | 激活当前目录 `.venv` |
| `fetch` | fastfetch |
| `duf` | 磁盘使用（仅本地） |
| `proxy` / `noproxy` / `show_proxy` | 代理开关与查看 |

Git 别名：`git st`（status）、`git lg`（log 图）、`git dfs`（diff --stat）、`git df`（diff）。
