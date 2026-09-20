# Dotfiles 项目说明

使用 **dotbot** 管理的 Linux dotfiles：BSPWM 平铺桌面 + 命令行工作流，路径遵循 XDG。项目概览见 [README](README.md)。

## 核心理念

- **Unix 哲学**：一个工具只做一件事，靠组合完成复杂功能，重视简洁与可维护。
- **平铺式窗口管理**：BSPWM，键盘驱动，减少窗口管理的认知负担。
- **命令行优先**：优先 CLI 工具与脚本自动化，GUI 只在必要时用。

这是所有取舍的依据：新增功能优先复用已有工具与函数库，不造重复轮子。

## 重要说明

只改本仓库，**不要**直接改 `~/.config/` 下的文件（那是 `./install` 生成的软链）；改完重跑 `./install` 由 dotbot 重新链接。

## Dotbot 配置

`conf.d/` 下按环境组合，`default` 始终运行，其余用参数追加：

| 文件 | 用途 |
|------|------|
| `default.conf.yaml` | 命令行环境（Shell、ZSH、VIM、Git、邮件、开发工具等） |
| `desktop.conf.yaml` | 桌面环境（BSPWM、SXHKD、Polybar、Rofi、Alacritty、FCITX5 等） |
| `rpi.conf.yaml` | 树莓派专用 |
| `setup.conf.yaml` | 基础依赖（apt 装 jq），仅初始化系统用 |

配置格式为「**目标路径: 源文件**」，左侧是系统实际位置，右侧是本仓库文件：

```yaml
$XDG_CONFIG_HOME/zsh/.zshrc: config/zsh/zshrc.zsh
```

## 环境变量

`config/environment`（shell 语法）是唯一源头，把各软件的配置/数据/缓存重定向到 XDG 目录。它被链接到三个加载点：`.zshenv`（Shell 全量）、`~/.xsessionrc`（X session 全量）、`environment.d/60-xdg.conf`（systemd user，**子集**）。路径对不上时先查它。

## 主题系统

`themes/colors/<theme>/colors.toml` + `themes/templates/<app>.tpl` → `~/.config/<app>/`（渲染产物，不手改）。CLI 工具跟随终端 16 色、无需模板；GUI 应用（Polybar/Rofi/Dunst/Zathura）需独立模板。入口是 `settings` 菜单。

## 脚本约定

- 用户入口在 `scripts/`，桌面入口在 `desktop/scripts/`，树莓派入口在 `rpi/scripts/`，均整个目录链接到 `~/.local/bin`。
- 第三方脚本也放 `scripts/`，但文件头必须注明来源。
- 设置相关复用逻辑在 `settings/`（库在 `settings/lib/`）。
- 界面统一走 `selectors.sh` 的 `select_ui`（由 `SELECTOR_UI` 决定 rofi/fzf，组件不感知）；消息统一走 `notify.sh` 的 `notify`。
- 无构建与测试框架。

## 文档导航

上面是大多数工作所需的要点；需要深入时查对应文档，不要凭目录猜：

| 主题 | 文档 |
|------|------|
| **想加东西**（软件配置/脚本/设置项/开关/主题/模板） | [docs/extending.md](docs/extending.md) |
| **名词的规范含义**、易混词（config/conf.d、主题/colors、脚本位置） | [docs/CONTEXT.md](docs/CONTEXT.md) |
| 安装/更新/卸载、conf.d 组合、submodule、本地覆盖 | [docs/installation.md](docs/installation.md) |
| 整体结构、dotbot 装配、XDG 细节、脚本分层、主题渲染流程 | [docs/architecture.md](docs/architecture.md) |
| 主题颜色/模板、新增主题或应用 | [docs/theming.md](docs/theming.md) |
| 设置菜单组件、新增设置项、内部脚本 API | [docs/settings.md](docs/settings.md) |
| 维护笔记（Git 索引技巧、预览缓存、已知问题、待办） | [docs/maintenance.md](docs/maintenance.md) |
| 为什么这样设计、当初排除了什么 | [docs/adr/](docs/adr/) |
| 某软件的配置放在哪 | [docs/reference/software.md](docs/reference/software.md) |
| `~/.local/bin` 各命令 | [docs/reference/scripts.md](docs/reference/scripts.md) |
| 快捷键 | [docs/reference/keybindings.md](docs/reference/keybindings.md) |
| OpenCode 自身配置（agents/skills/命令） | [config/opencode/AGENTS.md](config/opencode/AGENTS.md) |

总索引：[docs/README.md](docs/README.md)。
