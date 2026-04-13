# Dotfiles 项目说明

这是一个使用 **dotbot** 管理的 dotfiles 项目，体现了对 Unix 哲学的坚持和对高效工作流的追求。

## 核心理念

### Unix 哲学
- 一个软件只解决一个问题
- 选用专业工具完成特定任务
- 通过工具组合实现复杂功能
- 重视简洁、可维护的系统设计

### 平铺式窗口管理
- 采用 BSPWM 平铺式窗口管理器
- 最大化屏幕利用效率
- 减少窗口管理的认知负担
- 通过键盘快捷键高效操作

### 命令行优先
- 优先使用命令行程序
- 重视终端工具的效率
- 通过脚本自动化常规任务
- 避免图形界面的冗余操作

## 重要说明

修改系统配置时，**不要**直接修改 `~/.config/` 下的文件，而是修改本项目中的对应文件。运行 `./install` 后，dotbot 会自动将配置链接到系统。

## Dotbot 配置文件

配置文件位于 `conf.d/` 目录，按需求选择性运行：

| 文件 | 用途 |
|------|------|
| `default.conf.yaml` | 命令行环境配置（Shell、ZSH、VIM、Git、邮件、开发工具等） |
| `desktop.conf.yaml` | 桌面环境配置（BSPWM、SXHKD、Polybar、Rofi、Alacritty、FCITX5 等） |
| `rpi.conf.yaml` | 树莓派专用配置 |
| `setup.conf.yaml` | 基础环境依赖（仅初始化系统时使用，apt 安装 jq） |

## 配置格式说明

配置文件中，**左侧是目标路径**（系统实际位置），**右侧是源文件路径**（本项目中的文件）。

例如: `$XDG_CONFIG_HOME/zsh/.zshrc: config/zsh/zshrc.zsh` 表示系统的 `~/.config/zsh/.zshrc` 链接到本项目的 `config/zsh/zshrc.zsh`。