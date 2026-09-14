# 维护者笔记

面向本仓库的维护与扩展：内部机制、版本控制约定、已知问题与待办。日常使用者不需要读这里。

## 版本控制

`.gitignore` 的 `**/colors.*` 用于忽略主题系统的**渲染产物**（因为 `~/.config/*` 软链回仓库，生成的颜色文件会落进仓库）。这些文件不应手改、也不该提交。

> 该模式会**误伤主题源文件** `themes/colors/<theme>/colors.toml`。新增主题后需确认源文件已纳入版本控制（必要时 `git add -f`，或把规则改成只忽略具体生成路径，如 `desktop/alacritty/colors.toml`）。否则克隆仓库拿不到任何主题。

### 本地改动不追踪（skip-worktree）

`desktop/fontconfig/fonts.conf` 会被设置菜单的"字体"项改写。仓库需要保留一份默认版本供初次安装，但不希望记录本机的字体偏好，因此对本机该文件启用 Git 的 `skip-worktree`：

```sh
git update-index --skip-worktree desktop/fontconfig/fonts.conf
```

- 这是**本地索引标志，不随仓库提交**；换机器或重新 clone 后需重新执行一次。
- 文件仍被跟踪，仓库保留已提交的默认版本；本地改动留在磁盘但不进 `git status`。
- 需要主动提交一次本地改动、或与上游同步该文件时：

```sh
git update-index --no-skip-worktree desktop/fontconfig/fonts.conf
# 处理（commit / checkout / stash）后，再设回 --skip-worktree
```

- `config/pi/settings.json` 同样会被设置项改动，但**暂不**做此处理，保持正常追踪。

## 维护约定

| 你要做的事 | 需要改的地方 |
|------------|--------------|
| 新增一个软件配置 | 源文件放到 `config/` 或 `desktop/`，在对应 `conf.d/*.yaml` 加链接声明 |
| 新增脚本 | 放进 `scripts/`（自动链接）；桌面相关复用逻辑放 `settings/` |
| 新增环境变量 | `config/environment`（必要时同步 `config/environment.d/xdg.conf`） |
| 新增主题 / 应用模板 | 见 [主题系统](theming.md) |
| 新增设置项 | 见 [设置菜单](settings.md#新增设置项) |

面向 AI 助手与本仓库的通用约定另见根目录 [`AGENTS.md`](../AGENTS.md)。

## 内部脚本 API（`settings/`）

函数库不作为用户命令暴露，被 `settings` 与各设置项 source；清单与职责见 [架构与设计](architecture.md#脚本分层)，各函数用法见 [设置菜单](settings.md)。下面只记录维护相关的特殊点。

## 预览缓存

预览图按 UI 分工，各取所长：

- **fzf（TUI）**：`img-preview.py` 导入 `image_cache.py`，把缩放后的预览 PNG 缓存到 `$XDG_CACHE_HOME/image-cache/`（默认 `~/.cache/image-cache/`）。缓存键 = sha1(源路径 + mtime + 大小 + 目标尺寸)，源变化自动失效；写入时清理 14 天未过期的条目。JPEG 大图首次缩放开销大（约 150ms），命中约 0.2ms。
- **rofi（GUI）**：直接传原图路径（`wallpaper-image.sh` 返回源图，`font-sample.sh` 返回自渲染样张），由 rofi 自行加载与缓存图片——避免 rofi 弹出前串行为每项 spawn 子进程导致打开变慢。

> 清空 fzf 缓存：`rm -rf ~/.cache/image-cache`。

## 已知问题

- **sxhkd 启动 EPIPE**：快捷键启动时 stdout 是 socket，`echo` 会触发 SIGPIPE 中断脚本（`set -e` 下直接退出）。`epipe_init()` 忽略 SIGPIPE，且非 tty 时把输出重定向到 `~/.local/state/settings/logs/<脚本名>.log`。
- **bspwm 重载吞通知**：`bspc wm -r` 会重跑 bspwmrc，其中 `_s dunst` 会重启 dunst，导致刚发的通知被吞。主题切换因此先重载各软件、等新 dunst 就绪（`wait_dunst_ready`）再 `notify`。

## 待办

- opencode / pi agent - 检查是否支持主题配置
- vscode - 参考 Omarchy 的 `vscode-theme.json.tpl`
