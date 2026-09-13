# 软件与配置路径

下表列出各软件的配置在本仓库中的位置。系统里的实际路径由 `conf.d/*.conf.yaml` 的映射决定，详见[架构与设计](../architecture.md)。

## Shell 环境

| 软件 | 配置路径 |
|------|----------|
| 环境变量（XDG 重定向源头） | `config/environment`（systemd 子集在 `config/environment.d/`） |
| ZSH + Zinit + Powerlevel10k | `config/zsh/` |
| Bash | `config/bashrc` |
| Starship（已链接，当前未启用） | `config/starship.toml` |
| Atuin | `config/atuin/config.toml` |
| FZF / Zoxide | ZSH 插件（`config/zsh/zshrc.zsh`） |
| fd / rg | 外部命令，被 ZSH/FZF 调用 |

## 编辑器 & 终端

| 软件 | 配置路径 |
|------|----------|
| Vim + vim-plug | `config/vim/` |
| TMUX + TPM + nord-tmux | `config/tmux/tmux.conf` |
| herdr（终端复用器） | `config/herdr/config.toml` |

## 文件管理 & 系统信息

| 软件 | 配置路径 |
|------|----------|
| yazi | `config/yazi/` |
| FastFetch / bat | `config/fastfetch/` / `config/bat/` |

## 邮件系统

| 软件 | 配置路径 |
|------|----------|
| NeoMutt / offlineimap / notmuch / himalaya / pass | `config/mail/` |

## 桌面环境

| 软件 | 配置路径 |
|------|----------|
| BSPWM + sxhkd | `desktop/bspwm/` |
| Polybar | `desktop/polybar/` |
| Rofi | `desktop/rofi/` |
| Alacritty / Ghostty / URxvt | `desktop/alacritty/`、`desktop/ghostty/`、`desktop/X11/` |
| Dunst / Zathura / MPV | `desktop/dunst.conf`、`desktop/zathura/`、`desktop/mpv/` |
| Picom / Redshift / 字体 | `desktop/picom.conf`、`desktop/redshift.conf`、`desktop/fontconfig/fonts.conf` |
| 桌面入口文件（.desktop） | `desktop/applications/` |
| Udiskie | `desktop/udiskie/config.yml` |
| FCITX5-RIME | `desktop/fcitx5-rime/` + `data/rime-ice/` |

## 开发 & AI 工具

| 软件 | 配置路径 |
|------|----------|
| Git | `config/git/config` |
| UV / Bun / Python | `config/sources/` |
| Pi / OpenCode | `config/pi/` / `config/opencode/` |

## 其他随仓库分发

| 内容 | 路径 |
|------|------|
| 动态壁纸 | `data/dynamic-wallpaper/` |
| RIME 词库（雾凇拼音） | `data/rime-ice/` |
| binup 配置 | `desktop/builtin/binup.toml`（桌面）、`rpi/builtin/binup.toml`（树莓派） |
