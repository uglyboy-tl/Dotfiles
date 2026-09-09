# Getting Started

## 项目概览

这是一个使用 dotbot 管理的个人 dotfiles 仓库，体现了对 Unix 哲学的坚持和对高效工作流的追求。

核心理念：
- 平铺式窗口管理（BSPWM）
- 命令行优先
- XDG 目录规范
- 工具组合完成复杂功能

## 安装

### 基础安装（仅命令行环境）

```bash
git clone https://github.com/uglyboy-tl/dotfiles.git ~/.local/share/dotfiles
cd ~/.local/share/dotfiles
./install
```

`./install` 默认运行 `conf.d/default.conf.yaml`，包含 Shell、VIM、TMUX、Git 等基础配置。

### 桌面环境安装

```bash
./install desktop
```

额外运行 `conf.d/desktop.conf.yaml`，包含 BSPWM、Polybar、Rofi、Alacritty 等桌面组件。

### 树莓派安装

```bash
./install rpi
```

运行 `conf.d/rpi.conf.yaml`，针对树莓派的专用配置。

### 组合安装

可以同时传入多个配置名：

```bash
./install desktop rpi
```

### 重新安装

直接再次运行 `./install` 即可，dotbot 会自动处理符号链接的更新（`relink: true`）。

## Dotbot 工作原理

### 配置文件结构

```
conf.d/
├── default.conf.yaml    # 命令行环境（默认）
├── desktop.conf.yaml    # 桌面环境
├── rpi.conf.yaml        # 树莓派专用
└── setup.conf.yaml      # 基础依赖（apt install jq）
```

### 配置文件格式

每个 `.conf.yaml` 包含以下阶段：

1. **defaults** - 默认选项
2. **clean** - 清理旧符号链接
3. **shell** - 执行 shell 命令（如 git submodule 更新）
4. **link** - 创建符号链接（核心）
5. **crontab** - 定时任务（desktop.conf 中使用）

### 符号链接映射规则

配置文件中，**左侧是目标路径**（系统实际位置），**右侧是源文件路径**（仓库中的文件）。

例如：
```yaml
$XDG_CONFIG_HOME/zsh/.zshrc:
  path: config/zsh/zshrc.zsh
  force: true
```

表示系统的 `~/.config/zsh/.zshrc` 链接到仓库的 `config/zsh/zshrc.zsh`。

### install 脚本

`install` 脚本的执行流程：
1. 同步 dotbot 子模块
2. 遍历传入的配置名
3. 对每个配置名运行 dotbot：`dotbot -c conf.d/<name>.conf.yaml`

## 配套软件清单

### Shell 环境

| 软件 | 用途 | 配置路径 |
|------|------|----------|
| ZSH | 默认 Shell | `config/zsh/zshrc.zsh` |
| Zinit | ZSH 插件管理器 | `config/zsh/zinit/` |
| Powerlevel10k | ZSH 主题 | 通过 Zinit 加载 |
| Starship | 跨 Shell 提示符 | `config/starship.toml` |
| Atuin | 历史记录同步 | `config/atuin/config.toml` |
| FZF | 模糊查找 | ZSH 插件 |
| Zoxide | 智能 cd | ZSH 插件 |
| fd | 文件查找 | 配合 FZF |
| ripgrep (rg) | 内容搜索 | 配合 FZF |

### 编辑器

| 软件 | 用途 | 配置路径 |
|------|------|----------|
| Vim | 终端编辑器 | `config/vim/vimrc` |
| vim-plug | Vim 插件管理器 | `config/vim/plug.vim` |

### 终端多路复用器

| 软件 | 用途 | 配置路径 |
|------|------|----------|
| TMUX | 终端会话管理 | `config/tmux/tmux.conf` |
| TPM | TMUX 插件管理器 | 自动安装 |
| nord-tmux | TMUX 主题 | 通过 TPM 加载 |
| tmux-suspend | TMUX 挂起 | 通过 TPM 加载 |

### 文件管理器

| 软件 | 用途 | 配置路径 |
|------|------|----------|
| lf | 终端文件管理器 | `config/lf/lfrc` |
| yazi | 终端文件管理器 | `config/yazi/yazi.toml` |

### 系统信息

| 软件 | 用途 | 配置路径 |
|------|------|----------|
| FastFetch | 系统信息展示 | `config/fastfetch/config.jsonc` |
| bat | 带语法高亮的 cat | `config/bat/config` |

### 邮件系统

| 软件 | 用途 | 配置路径 |
|------|------|----------|
| NeoMutt | 终端邮件客户端 | `config/mail/muttrc` |
| offlineimap | IMAP 邮件同步 | `config/mail/offlineimap.conf` |
| notmuch | 邮件索引和搜索 | `config/mail/notmuch.conf` |
| himalaya | Rust 邮件客户端 | `config/mail/himalaya.toml` |
| pass | 密码管理 | GPG + pass |

### 桌面环境

| 软件 | 用途 | 配置路径 |
|------|------|----------|
| BSPWM | 平铺窗口管理器 | `desktop/bspwm/bspwmrc` |
| sxhkd | 快捷键守护进程 | `desktop/bspwm/sxhkdrc` |
| Polybar | 状态栏 | `desktop/polybar/` |
| Picom | 窗口合成器 | `desktop/picom.conf` |
| Rofi | 应用启动器 | `desktop/rofi/` |
| Dunst | 桌面通知 | `desktop/dunst.conf` |
| Alacritty | GPU 加速终端 | `desktop/alacritty/` |
| Ghostty | 终端模拟器 | `desktop/ghostty/` |
| URxvt | 轻量终端 | `desktop/X11/rxvt-unicode` |
| feh | 图片查看器 | 通过 mimeapps.list |
| Zathura | PDF 阅读器 | `desktop/zathura/` |
| MPV | 媒体播放器 | `desktop/mpv/mpv.conf` |
| FCITX5-RIME | 中文输入法 | `desktop/fcitx5-rime/` |
| UDiskie | 自动挂载 | `desktop/udiskie/config.yml` |

### 开发工具

| 软件 | 用途 | 配置路径 |
|------|------|----------|
| Python/PIP | Python 包管理 | `config/sources/pip.conf` |
| UV | Python 包管理器 | `config/sources/uv.toml` |
| Bun | JS 运行时/包管理 | `config/sources/bunfig.toml` |
| Git | 版本控制 | `config/git/config` |

### AI 工具

| 软件 | 用途 | 配置路径 |
|------|------|----------|
| Pi | 编码代理 | `config/pi/` |
| OpenCode | AI 编码助手 | `config/opencode/` |

### 系统工具

| 软件 | 用途 | 配置路径 |
|------|------|----------|
| herdr | 终端多路复用 | `config/herdr/config.toml` |
| binup | 二进制文件管理 | `desktop/builtin/binup.toml` |

## 自定义脚本

脚本通过 dotbot 自动链接到 `~/.local/bin/`：

### 通用脚本（`scripts/`）

| 脚本 | 用途 |
|------|------|
| `binup` | 二进制文件管理器 |
| `peon` | 自定义工具 |
| `sync_imap_mail` | 邮件同步 |
| `update-peon` | 更新 peon |
| `update-pi` | 更新 Pi |

### 桌面脚本（`desktop/scripts/`）

| 脚本 | 用途 |
|------|------|
| `barify` | 音量控制集成 Polybar |
| `dwall.sh` | 动态壁纸 |
| `rofi-bluetooth` | 蓝牙管理 Rofi 菜单 |
| `rofi-powermenu` | 电源管理 Rofi 菜单 |
| `theme` | 主题切换脚本 |

### 树莓派脚本（`rpi/scripts/`）

| 脚本 | 用途 |
|------|------|
| `pg-back` | PostgreSQL 数据库备份 |
| `rpi-backup` | 树莓派备份 |

## 本地覆盖机制

### 不进版本控制的本地覆盖

以下文件支持本地覆盖，不会被 dotbot 链接覆盖，适合存放个人敏感配置：

| 应用 | 覆盖文件 |
|------|----------|
| ZSH | `~/.config/local/zshrc.before`, `~/.config/local/zshrc.after` |
| Vim | `~/.config/local/vimrc` |
| TMUX | `~/.config/local/tmux` |
| Git | `~/.config/local/git/local` |

### 进版本控制的额外配置

以下文件被版本控制管理，按需加载（文件存在即加载）：

| 文件 | 链接目标 | 加载条件 |
|------|----------|----------|
| `rpi/zshrc.rpi` | `~/.config/zsh/zshrc.rpi` | 文件存在 |

## 环境变量

### XDG 目录规范

所有配置遵循 XDG Base Directory 规范：

```bash
XDG_DATA_HOME=$HOME/.local/share
XDG_CONFIG_HOME=$HOME/.config
XDG_STATE_HOME=$HOME/.local/state
XDG_CACHE_HOME=$HOME/.cache
```

环境变量通过两种方式设置：
- `config/environment` - ZSH 环境变量（`~/.config/zsh/.zshenv`）
- `config/environment.d/xdg.conf` - Systemd 环境变量

## 依赖的子模块

### 通用（default）

```
dotbot                 - 配置管理器
dotbot-plugins/crontab - 定时任务插件
config/vim/vim-plug    - Vim 插件管理器
config/zsh/zinit       - ZSH 插件管理器
config/opencode        - OpenCode AI 配置
data/rime-ice          - RIME 输入法方案
```

### 桌面环境（desktop）

```
desktop/mpv/thumbfast  - MPV 缩略图预览
desktop/mpv/uosc       - MPV 现代 UI
data/dynamic-wallpaper - 动态壁纸
```

## 快捷操作速查

### ZSH 别名

```bash
size <dir>     # 查看目录大小（排序）
runv           # 激活 Python 虚拟环境
duf            # 磁盘使用（仅本地）
fetch          # fastfetch 别名
proxy          # 开启代理
noproxy        # 关闭代理
show_proxy     # 显示代理地址
```

### Git 别名

```bash
git st     # git status -sb
git lg     # git log --oneline --graph --decorate --all
git dfs    # git diff --stat
git df     # git diff
```

### TMUX 前缀键

前缀键为 `Ctrl+a`（而非默认的 `Ctrl+b`）。

### BSPWM 快捷键

详见 `desktop/bspwm/sxhkdrc`，常用：

```
Super + Return     打开 Ghostty
Super + r          Rofi 启动器
Super + e          Yazi 文件管理器
Super + {1-9}      切换桌面
Super + Space      浮动/平铺切换
Super + w          关闭窗口
```
