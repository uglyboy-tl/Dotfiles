# 安装与运维

涵盖安装、更新、按需选择配置，以及不改仓库就能覆盖配置的方法。

## 安装

```bash
git clone https://github.com/uglyboy-tl/dotfiles.git ~/.local/share/dotfiles
cd ~/.local/share/dotfiles
./install
```

`install` 是 dotbot 的薄封装：先同步 `dotbot` 与插件 submodule，然后**按顺序**执行配置文件。默认第一个总是 `default`；常规安装只取**第一个**环境参数（`desktop`/`rpi`），多余的会被忽略。

`setup` 必须是**第一个参数**（可后接 `desktop`/`rpi`），此时**只装包、不建链接**：把 `default` 与后面的单元都当成 `packages-<unit>.conf.yaml` 依次安装，全部以 root 运行。apt 插件只在 `setup` 模式加载，其余情况加载 crontab 插件。

```bash
./install                # default
./install desktop        # default + desktop
./install rpi            # default + rpi
./install setup          # 只装 CLI 基础包
./install setup desktop  # 只装 CLI 基础包 + 桌面包
./install setup rpi      # 只装 CLI 基础包 + 树莓派包
```

支持的配置单元：

| 参数 | 文件 | 内容 |
|------|------|------|
| （默认） | `conf.d/default.conf.yaml` | 命令行环境：shell、vim、tmux、git、邮件、开发工具、AI 工具 |
| `desktop` | `conf.d/desktop.conf.yaml` | 桌面环境：BSPWM、Polybar、Rofi、终端、输入法、MPV 等 |
| `rpi` | `conf.d/rpi.conf.yaml` | 树莓派专用：备份脚本与 crontab |
| `setup` | `conf.d/packages-default.conf.yaml` | 命令行环境 apt 依赖；`setup` 模式下以 root 运行，只装包 |

`setup` 后接 `desktop`/`rpi` 时，会另跑 `conf.d/packages-desktop.conf.yaml` / `conf.d/packages-rpi.conf.yaml`（只装包，不建链接）。

**重复运行即更新**：dotbot 会先 `clean` 掉 `~/`、`~/.local/bin`、`$XDG_CONFIG_HOME` 下旧的符号链接，再按最新配置重建，因此新增/移动配置只要改 `conf.d` 后重跑即可。

## 第三方依赖（submodule）

下列组件以 git submodule 引入，`./install` 时会自动拉取，无需手动处理：

- `dotbot`、`dotbot-plugins/crontab`、`dotbot-plugins/apt`（安装器本身与指令插件，由 `install` 统一拉取）
- `config/zsh/zinit`、`config/vim/vim-plug`（编辑器/Shell 插件管理器）
- `config/opencode`（OpenCode 配置，见 [config/opencode/AGENTS.md](../config/opencode/AGENTS.md)）
- `desktop/mpv/{uosc,thumbfast}`（播放器界面）
- `data/dynamic-wallpaper`、`data/rime-ice`

克隆时若想一并取回：`git clone --recursive ...`，否则安装脚本会补拉。

## 本地覆盖（不进版本控制）

通用配置之上留了覆盖点，用于放机器私有内容（本地路径、密钥等）：

| 应用 | 覆盖文件 | 说明 |
|------|----------|------|
| ZSH | `~/.config/local/zshrc.before` | 基础环境变量之前 |
| ZSH | `~/.config/local/zshrc.plugins` | 追加 zinit 插件 |
| ZSH | `~/.config/local/zshrc.after` | 最后加载 |
| Vim | `~/.config/local/vimrc` | 由 `config/vim/vimrc` source |
| TMUX | `~/.config/local/tmux` | 由 `config/tmux/tmux.conf` source |
| 屏保 | `~/.config/local/idle-screensaver` | 由 `desktop/idle-screensaver/idle-screensaver.sh` source，设 `IDLE_SCREENSAVER_DIR` 等 |
| Git | `~/.config/git/local` | 由 `config/git/config` include |
| Polybar | `~/.config/local/polybar/bluetooth-battery.conf` | 蓝牙电量组件：每个 `[节]` 一个设备，字段 `mac`（优先）/`name`（兜底）/`icon` |

这些文件不存在时会被静默跳过，不会报错。

## 启用 systemd user 服务

`desktop/systemd/` 下的 unit 由 dotbot 链接到 `$XDG_CONFIG_HOME/systemd/user/`，但 dotbot 不改 systemd 状态，需要手动启用（一次即可，之后随会话自启）：

```bash
systemctl --user daemon-reload
systemctl --user enable --now idle-screensaver-dbus.service   # 屏保抑制（org.freedesktop.ScreenSaver）
systemctl --user enable --now herdr-server.service            # Herdr 常驻 server（default session）
```

其他 unit（如 `jellyfin-mpv-shim.service`）同理，按需启用。未启用的后果只是对应功能缺失，不影响其余配置。

> Herdr 若已在跑（旧配置由 `bspwmrc` 起的手工进程），先 `herdr server stop` 再启用：否则 `herdr server` 会立刻退出，unit 进入 failed（`systemctl --user reset-failed herdr-server.service` 后可重试）。

## 平台差异

- **桌面配置**假设 X11 会话（BSPWM），依赖 `xrandr`、`xrdb` 等。
- **树莓派配置** `rpi` 额外安装备份脚本（`pg-back`、`rpi-backup`）并写入 crontab，见 [脚本参考](reference/scripts.md)。
- 环境变量在 systemd 下只有子集生效，原因见 [架构与设计](architecture.md#环境变量与-xdg)。

## 卸载

本仓库不做系统级卸载。撤销方式是删除 dotbot 创建的符号链接、恢复被覆盖的配置；如无备份，可从 dotbot 的 `clean` 行为得知它只删除**指向本仓库**的链接，不影响其他文件。
