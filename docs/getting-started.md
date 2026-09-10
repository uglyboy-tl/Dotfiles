# Getting Started

## 文档导航

- `themes.md` - 主题系统（颜色策略、渲染、添加新主题/应用）
- `settings.md` - 设置菜单（主题/壁纸/字体/快捷键，含新增设置项约定）

## 项目概览

使用 dotbot 管理的 dotfiles 仓库，核心理念：BSPWM 平铺窗口管理、命令行优先、XDG 目录规范。

## 安装

```bash
git clone https://github.com/uglyboy-tl/dotfiles.git ~/.local/share/dotfiles
cd ~/.local/share/dotfiles
./install          # 默认：命令行环境
./install desktop  # 桌面环境
./install rpi      # 树莓派
```

支持组合：`./install desktop rpi`。重新运行即可更新。

## 配套软件

### Shell 环境

| 软件 | 配置路径 |
|------|----------|
| ZSH + Zinit + P10k | `config/zsh/` |
| Starship | `config/starship.toml` |
| Atuin | `config/atuin/config.toml` |
| FZF / Zoxide / fd / rg | ZSH 插件 |

### 编辑器 & 终端

| 软件 | 配置路径 |
|------|----------|
| Vim + vim-plug | `config/vim/` |
| TMUX + TPM + nord-tmux | `config/tmux/tmux.conf` |

### 文件管理 & 系统信息

| 软件 | 配置路径 |
|------|----------|
| yazi | `config/yazi/` |
| FastFetch / bat | `config/fastfetch/` / `config/bat/` |

### 邮件系统

| 软件 | 配置路径 |
|------|----------|
| NeoMutt / offlineimap / notmuch / himalaya / pass | `config/mail/` |

### 桌面环境

| 软件 | 配置路径 |
|------|----------|
| BSPWM + sxhkd | `desktop/bspwm/` |
| Polybar | `desktop/polybar/` |
| Rofi | `desktop/rofi/` |
| Alacritty / Ghostty / URxvt | `desktop/` |
| Dunst / Zathura / MPV | `desktop/` |
| FCITX5-RIME | `desktop/fcitx5-rime/` |

### 开发 & AI 工具

| 软件 | 配置路径 |
|------|----------|
| Git | `config/git/config` |
| UV / Bun / Python | `config/sources/` |
| Pi / OpenCode | `config/pi/` / `config/opencode/` |

## 自定义脚本

链接到 `~/.local/bin/`：

| 脚本 | 用途 |
|------|------|
| `binup` | 二进制文件管理器 |
| `peon` | 自定义工具 |
| `sync_imap_mail` | 邮件同步 |
| `settings` | 设置菜单（主题/壁纸/字体/快捷键，`--gui` 走 rofi） |
| `rofi-bluetooth` / `rofi-powermenu` | Rofi 菜单 |
| `dwall.sh` | 动态壁纸 |

## 本地覆盖

| 应用 | 覆盖文件（不进版本控制） |
|------|--------------------------|
| ZSH | `~/.config/local/zshrc.{before,after}` |
| Vim | `~/.config/local/vimrc` |
| TMUX | `~/.config/local/tmux` |
| Git | `~/.config/local/git/local` |

## 环境变量

遵循 XDG 规范，通过 `config/environment` 和 `config/environment.d/xdg.conf` 设置。

## 快捷操作

```bash
# ZSH 别名
size <dir>     # 目录大小
runv           # 激活 Python venv
proxy/noproxy  # 代理开关

# Git 别名
git st / lg / dfs / df

# TMUX
前缀键: Ctrl+a

# BSPWM（常用）
Super + Return    Ghostty
Super + r         Rofi
Super + e         Yazi
Super + ;         设置菜单（settings --gui）
Super + {1-9}     切换桌面
```
