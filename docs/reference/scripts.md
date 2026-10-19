# 脚本参考

`~/.local/bin` 下各命令的用途与源文件位置。链接分两种：`scripts/*` 与 `desktop/scripts/*` 整体批量链接，`settings/settings` 与 `settings/setting-keybindings.sh` 单独链接（见[安装与运维](../installation.md)）。第三方脚本与自研脚本同在 `scripts/`，靠文件头署名区分，见 [ADR-0003](../adr/0003-scripts-layout.md)。

## 用户命令

| 命令 | 源文件 | 用途 |
|------|--------|------|
| `settings` | `settings/settings` | 设置菜单入口（主题/壁纸/字体/快捷键/关于），`--gui` 走 rofi，详见 [设置菜单](../settings.md) |
| `keybindings` | `settings/setting-keybindings.sh` | 快捷键执行菜单（选中即执行，sxhkd `Super + k`） |
| `binup` | `scripts/binup` | 自研二进制文件管理器（安装/更新 CLI 工具），配置见 `desktop/binup.toml` |
| `peon` / `update-peon` | `scripts/peon` / `scripts/update-peon` | peon-ping 提示音（配合 Claude Code hooks，第三方）及升级 |
| `update-pi` | `scripts/update-pi` | 更新 Pi agent |
| `sync_imap_mail` | `scripts/sync_imap_mail` | offlineimap 同步 + notmuch 索引与自动打标签 |
| `24-bit-color.sh` | `scripts/24-bit-color.sh` | 终端真彩色（24-bit）测试（第三方，源自 tmux） |
| `node` | `scripts/node` | `bun` 兼容垫片，把 `node` 调用转发给 `bun` |

## 桌面命令

| 命令 | 源文件 | 用途 |
|------|--------|------|
| `screenshot` | `desktop/scripts/screenshot` | 区域/全屏截图（保存 + 复制 + 通知，sxhkd `Print`） |
| `barify` | `desktop/scripts/barify` | 音量/亮度指示条（走 dunst/mako） |
| `brightness` | `desktop/scripts/brightness` | 外接显示器亮度（DDC/CI，经 ddcutil）+ 通知指示 |
| `dwall.sh` | `desktop/scripts/dwall.sh` | 动态壁纸，按时间切换，由 cron 每小时调用 |
| `bluetooth` | `desktop/scripts/bluetooth` | 蓝牙设备 rofi 菜单（sxhkd `Super + b`） |
| `reboot2bios` | `desktop/scripts/reboot2bios` | 重启进入 BIOS/UEFI |
| `reboot2win` | `desktop/scripts/reboot2win` | 重启进入 Windows（grub 条目） |

## polybar 菜单脚本

只有 polybar 调用的 rofi 菜单脚本放在 `desktop/polybar/scripts/`，**不**链入 `~/.local/bin`，由 polybar 以绝对路径调用。蓝牙菜单因绑定全局快捷键，作为命令放在 `desktop/scripts/bluetooth`。

| 脚本 | 用途 |
|------|------|
| `rofi-powermenu.sh` | 电源 rofi 菜单（polybar powermenu 模块点击） |
| `rofi-calendar.py` | rofi 月历弹出（polybar date 模块点击），主题 `desktop/rofi/calendar.rasi` |
| `rofi-sysinfo.py` | rofi 系统信息面板（CPU/内存/温度/网络/swap/uptime + 音量/亮度加减），主题 `desktop/rofi/sysinfo.rasi`。入口暂在 `cpu.ini` 中注释未启用 |

## 树莓派命令（`rpi` 配置）

| 命令 | 源文件 | 用途 |
|------|--------|------|
| `pg-back` | `rpi/scripts/pg-back` | 备份 PostgreSQL（docker）转储，保留最近 7 份；每天 0 点由 crontab 执行 |
| `rpi-backup` | `rpi/scripts/rpi-backup` | SD 卡镜像备份并压缩（`dd` + `pishrink`）；备份前清理可再生缓存/日志（约 400M），`--no-clean` 跳过，`--dry-run` 只看流程 |

## 树莓派外部工具（不在 dotfiles 里）

| 工具 | 位置 | 来源 | 当前版本 |
|------|------|------|----------|
| `pishrink.sh` | `/usr/local/bin/pishrink.sh` | [Drewsif/PiShrink](https://github.com/Drewsif/PiShrink)，手动安装（无 apt 归属，release 不带附件所以 `binup` 管不了） | v26.03.16，与最新 release 及 master 逐字节一致 |

检查与更新：

```bash
# 本地版本
sed -n 's/^version="\(.*\)"/\1/p' /usr/local/bin/pishrink.sh
# 与上游 master 比对（两个哈希一致即无需更新）
gh api repos/Drewsif/PiShrink/contents/pishrink.sh --jq .content | base64 -d | sha256sum
sha256sum /usr/local/bin/pishrink.sh
# 更新
gh api repos/Drewsif/PiShrink/contents/pishrink.sh --jq .content | base64 -d | sudo tee /usr/local/bin/pishrink.sh >/dev/null
sudo chmod 755 /usr/local/bin/pishrink.sh
```

`/usr/local/bin/` 下的脚本保持 `root:root 755`（它们由 `sudo` 执行，属主不能是普通用户）。
