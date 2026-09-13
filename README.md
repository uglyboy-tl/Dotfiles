# dotfiles

我的 Linux 个人配置：BSPWM 平铺桌面 + 命令行工作流。用 [dotbot](https://github.com/anishathalye/dotbot) 管理，一条 `./install` 把 shell、编辑器、桌面、开发与 AI 工具的配置软链到系统；路径统一遵循 XDG 规范，命令行 / 桌面 / 树莓派三种环境按需组合。

主要包含：

- **桌面**：BSPWM + sxhkd + Polybar + Rofi + Dunst + Picom，终端 Alacritty / Ghostty / URxvt
- **终端与 Shell**：ZSH + Zinit + Powerlevel10k、TMUX / herdr、yazi、Atuin、FZF + Zoxide
- **工作流**：统一设置菜单（主题 / 壁纸 / 字体 / 快捷键 / 关于）、自研主题渲染、邮件（offlineimap + notmuch + NeoMutt）
- **开发与 AI**：Git、UV / Bun / Python、Pi / OpenCode，配套 `binup` 管理 CLI 二进制

设计取向：Unix 哲学（一个工具只做一件事）、平铺窗口管理、命令行优先。

## 快速开始

```bash
git clone https://github.com/uglyboy-tl/dotfiles.git ~/.local/share/dotfiles
cd ~/.local/share/dotfiles
./install          # 默认：命令行环境
./install desktop  # 桌面环境
./install rpi      # 树莓派
```

依赖 `git`、`bash`、`curl`；依赖的第三方组件（dotbot、zinit、vim-plug、uosc、rime-ice 等）以 submodule 引入，安装时自动拉取。桌面配置需先装好对应软件（BSPWM、终端、Polybar、Rofi、Dunst 等）。`./install setup` 会用 apt 安装 `jq`。

支持组合，例如 `./install desktop rpi`；重复运行即可更新配置。

## 目录结构

```
conf.d/       dotbot 配置（按环境选择运行）
config/       命令行环境配置（shell、编辑器、邮件、开发工具等）
desktop/      桌面环境配置（BSPWM、Polybar、Rofi、终端等）
data/         外部数据（动态壁纸、RIME 词库等）
rpi/          树莓派专用配置
scripts/      自定义脚本（链接到 ~/.local/bin）
settings/     设置菜单与可复用脚本
themes/       主题颜色定义与模板
docs/         文档
```

## 文档

- [安装与运维](docs/installation.md)
- [架构与设计](docs/architecture.md)
- [主题系统](docs/theming.md)
- [设置菜单](docs/settings.md)
- 参考：[软件与配置路径](docs/reference/software.md) · [脚本](docs/reference/scripts.md) · [快捷键](docs/reference/keybindings.md)

完整文档索引见 [docs/](docs/README.md)。

## 致谢

大量配置与脚本来自开源社区，脚本内均保留了原作者署名。特别感谢 dotbot、zinit、Omarchy（主题规范）以及各软件的上游维护者。
