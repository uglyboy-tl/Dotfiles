# 架构与设计

本文解释这套 dotfiles 的组织方式，以及各部分如何协作。

## 总览

```
conf.d/          声明「哪个文件链接到哪里」——唯一的装配清单
   │
   ├── config/    命令行源文件（shell/vim/tmux/git/mail/...）
   ├── desktop/   桌面源文件（bspwm/polybar/rofi/...）
   │   └── scripts/  桌面脚本（settings/screenshot/common/...）
   ├── data/      随仓库分发的外部数据（壁纸、RIME 词库）
   └── rpi/       树莓派专用
scripts/         用户入口脚本（链接到 ~/.local/bin）
themes/          主题颜色 + 模板，渲染生成各应用颜色文件
```

设计遵循三点：**声明与内容分离**（`conf.d` 只声明映射，源文件各自独立）、**入口与库分离**（`scripts/` 面向用户，`desktop/scripts/common/` 被复用）、**渲染而非手改**（颜色由模板生成，不直接编辑产物）。

## dotbot 装配层

`conf.d/*.conf.yaml` 是唯一的装配声明，格式为「**目标路径: 源文件**」，左侧是系统实际位置，右侧是本仓库文件：

```yaml
$XDG_CONFIG_HOME/git/config: config/git/config
```

关键机制：

- **glob 链接**：`~/.local/bin/` 用 `path: scripts/*` 把整个目录下的脚本批量链接过去，新增脚本无需改配置。
- **clean**：每次运行先清理旧链接，保证幂等，删除的配置不会残留。
- **按环境组合**：`default` 始终运行，`desktop`/`rpi` 按参数叠加，避免笔记本、树莓派互相污染。

详见 [安装与运维](installation.md)。

## 环境变量与 XDG

`config/environment` 是**唯一源头**（shell 语法），被 dotbot 链接到三个加载点：

| 加载点 | 覆盖范围 |
|--------|----------|
| `~/.config/zsh/.zshenv` | Shell 全量 |
| `~/.xsessionrc` | X session 全量 |
| `~/.config/environment.d/60-xdg.conf` | systemd user（**子集**） |

第三处的源文件是 `config/environment.d/xdg.conf`，它是 systemd 语法的**子集**，缺少 `GNUPGHOME`、`DOCKER_CONFIG`、`NPM_*` 等变量。因此某些 systemd 服务读不到这些变量，排查环境变量问题时先区分是哪个加载点。

作用是把各软件的配置/数据/缓存从默认位置重定向进 XDG 目录，例如 `GNUPGHOME=$XDG_DATA_HOME/gnupg`、`NPM_CONFIG_CACHE=$XDG_CACHE_HOME/npm`。

## 脚本分层

```
scripts/                 用户入口（被链接到 ~/.local/bin）
├── binup / peon / ...   独立工具

desktop/scripts/         桌面脚本（被链接到 ~/.local/bin）
├── settings             设置菜单入口
├── screenshot           截图工具
└── common/              函数库，不直接暴露给用户
    ├── selectors.sh     界面抽象：select_ui / selector_gui_supported / epipe_init
    ├── notify.sh       消息抽象：notify / notify_error
    ├── render.sh        模板渲染：render <colors.toml> <tpl> <out>
    └── setting-*.sh     各设置项的「选择→校验→应用」实现
```

分层规则：

- **界面与逻辑解耦**：组件只调用 `select_ui`，不关心底层是 rofi 还是 fzf；界面由入口导出的 `SELECTOR_UI`（gui/tui）决定。
- **消息与平台解耦**：统一走 `notify`，GUI 下桌面通知，否则回退命令行。
- **选择器/消息/渲染都是可复用库**，新增设置项或工具时直接 source，不重复实现。

细节见 [设置菜单](settings.md)。

## 主题渲染流程

```
themes/colors/<theme>/colors.toml   （颜色定义，人工维护）
        │  render.sh 按 {{ 变量 }} 做 sed 替换
        ▼
themes/templates/<app>.tpl           （模板）
        ▼
~/.config/<app>/colors.*             （渲染产物，自动生成）
```

- 模板变量支持 `{{ name }}` 与去 `#` 的 `{{ name_strip }}`，另有派生变量（如 `selection_background`）。
- 渲染后按应用选择重载方式（信号/命令/重启），映射表在 `setting-theme.sh`。
- 未安装的应用会被跳过；所有模板都不可用时报错退出。

完整规则见 [主题系统](theming.md)。

## 状态与本地覆盖

- **运行状态**：主题、壁纸等把当前值写入 `~/.local/state/<name>/current`，供下次启动与菜单高亮读取。
- **本地覆盖**：`~/.config/local/*` 与 `~/.config/git/local` 用于放机器私有内容，不纳入版本控制，详见 [安装与运维](installation.md#本地覆盖不进版本控制)。
