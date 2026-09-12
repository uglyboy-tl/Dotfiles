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

查看或修改系统配置时，**不需要**查看或修改 `~/.config/` 下的文件，优先查看或修改本项目中的对应文件。运行 `./install` 后，dotbot 会自动将配置链接到系统。

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

## 环境变量

`config/environment`（shell 语法）是唯一源头，作用是把各软件的配置/数据/缓存从默认位置重定向到 XDG 目录。被 dotbot 链接到三个加载点：

- `$XDG_CONFIG_HOME/zsh/.zshenv` - Shell 环境（全量）
- `~/.xsessionrc` - X session（全量）
- `$XDG_CONFIG_HOME/environment.d/60-xdg.conf` - systemd --user（源文件 `config/environment.d/xdg.conf`，systemd 语法的**子集**，缺少 GNUPGHOME、DOCKER_CONFIG、NPM_* 等变量，某些 systemd 服务读不到）

环境变量与实际路径不匹配时，优先检查 `config/environment`。

## 主题系统

自研主题渲染：`themes/colors/<theme>/colors.toml` + `themes/templates/<app>.tpl` → `~/.config/<app>/`。

- CLI 工具跟随终端 16 色，不需要模板
- GUI 应用（Polybar/Rofi/Dunst/Zathura）需要独立模板
- 通过 `settings` 菜单切换（主题/壁纸/字体/快捷键，`--gui` 走 rofi），详见 `docs/themes.md`

## 脚本约定

- 用户入口在 `scripts/`（链接到 `~/.local/bin/`），桌面相关入口在 `desktop/scripts/`（也链接到 `~/.local/bin/`）
- 设置相关组件放 `settings/`（库/helper 在 `settings/lib/`），被 `settings`/`screenshot` 等脚本复用
- 选择器统一走 `selectors.sh`：界面类型由 `SELECTOR_UI`（gui/tui）决定，调用 `select_ui` 即可，组件不感知 rofi/fzf
- 消息统一走 `notify.sh`：GUI 下走桌面通知，不可用时回退命令行输出（`notify`/`notify_error`）