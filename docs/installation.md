# 安装与运维

涵盖安装、更新、按需选择配置，以及不改仓库就能覆盖配置的方法。

## 安装

```bash
git clone https://github.com/uglyboy-tl/dotfiles.git ~/.local/share/dotfiles
cd ~/.local/share/dotfiles
./install
```

`install` 是 dotbot 的薄封装：先同步 `dotbot` submodule，然后**按顺序**执行配置文件。默认第一个总是 `default`，其余由参数追加：

```bash
./install            # default
./install desktop    # default + desktop
./install desktop rpi  # default + desktop + rpi
```

支持的配置单元：

| 参数 | 文件 | 内容 |
|------|------|------|
| （默认） | `conf.d/default.conf.yaml` | 命令行环境：shell、vim、tmux、git、邮件、开发工具、AI 工具 |
| `desktop` | `conf.d/desktop.conf.yaml` | 桌面环境：BSPWM、Polybar、Rofi、终端、输入法、MPV 等 |
| `rpi` | `conf.d/rpi.conf.yaml` | 树莓派专用：备份脚本与 crontab |
| `setup` | `conf.d/setup.conf.yaml` | 初始依赖（apt 安装 `jq`），仅首次初始化系统用 |

**重复运行即更新**：dotbot 会先 `clean` 掉 `~/`、`~/.local/bin`、`$XDG_CONFIG_HOME` 下旧的符号链接，再按最新配置重建，因此新增/移动配置只要改 `conf.d` 后重跑即可。

## 第三方依赖（submodule）

下列组件以 git submodule 引入，`./install` 时会自动拉取，无需手动处理：

- `dotbot`、`dotbot-plugins/crontab`（安装器本身）
- `config/zsh/zinit`、`config/vim/vim-plug`（编辑器/Shell 插件管理器）
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
| Git | `~/.config/git/local` | 由 `config/git/config` include |

这些文件不存在时会被静默跳过，不会报错。

## 平台差异

- **桌面配置**假设 X11 会话（BSPWM），依赖 `xrandr`、`xrdb` 等。
- **树莓派配置** `rpi` 额外安装备份脚本（`pg-back`、`rpi-backup`）并写入 crontab，见 [脚本参考](reference/scripts.md)。
- 环境变量在 systemd 下只有子集生效，原因见 [架构与设计](architecture.md#环境变量与-xdg)。

## 卸载

本仓库不做系统级卸载。撤销方式是删除 dotbot 创建的符号链接、恢复被覆盖的配置；如无备份，可从 dotbot 的 `clean` 行为得知它只删除**指向本仓库**的链接，不影响其他文件。
