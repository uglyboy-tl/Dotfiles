# 扩展指南

想给这套配置**加东西**时的操作手册。每个场景给最小步骤；深入细节看链接。

改完记得**重跑 `./install`**才能生效（见文末[生效与验证](#生效与验证)）。

> 术语不确定先看 [术语表](CONTEXT.md)。

---

## 1. 新增一个软件的配置

**目标**：某个软件的配置文件纳入仓库管理。

1. 源文件放进 `config/<软件>/`（命令行）或 `desktop/<软件>/`（桌面）
   - 单文件应用也用目录：`desktop/picom/picom.conf`（而非平铺在 `desktop/` 下）
   - 例外：XDG 要求隐藏文件位置的（如 `~/.bunfig.toml`）源文件仍放对应目录（如 `config/sources/bunfig.toml`），只是目标路径特殊
2. 在对应 `conf.d/*.yaml` 加一行 `目标路径: 源文件`：

```yaml
$XDG_CONFIG_HOME/<软件>/<文件名>: <config|desktop>/<软件>/<文件名>
```

3. 重跑 `./install`。

**整个目录一起链接**（适合目录里多个文件都要管）：

```yaml
$XDG_CONFIG_HOME/<软件>: desktop/<软件>
```

> 目录整体链接 = 渲染产物会落回仓库。`desktop/` 下的产物已由 `.gitignore` 的 `desktop/*/colors.*` 覆盖，无需额外操作。

---

## 2. 新增一个脚本

放进 `scripts/`（命令行）、`desktop/scripts/`（桌面）或 `rpi/scripts/`（树莓派）。`glob: scripts/*` 会自动链入 `~/.local/bin`，**无需改配置**。

**约定**：

- 可执行（`chmod +x`）、`shebang` 明确
- 第三方脚本也直接放 `scripts/`，但**必须在文件头注明来源**（见 [ADR-0003](adr/0003-scripts-layout.md)）

**只被 WM 调用、不进 PATH 的助手**（如 `desktop/idle-screensaver.sh`）：放 `desktop/` 根，由 `bspwmrc` 用绝对路径调用，不加链接声明。

---

## 3. 新增一个环境变量

`config/environment` 是**唯一源头**。若该变量 systemd user 也要读，同步加到 `config/environment.d/xdg.conf`（它是子集）。

> 三个加载点与差异见 [架构与设计 → 环境变量与 XDG](architecture.md#环境变量与-xdg)。

---

## 4. 新增一个设置项（菜单里的"切换"）

在 `settings/` 建 `setting-<name>.sh`，照 `setting-theme.sh` 的函数模板：

```bash
source "$DOTFILES_DIR/settings/lib/selectors.sh"
source "$DOTFILES_DIR/settings/lib/notify.sh"
epipe_init

select_<name>() { X=$(select_ui -p "..." -d "$(get_items)" -s "$(get_current)") || exit 0; }
validate_<name>() { ...; return 1; }   # 失败返回 1，不退出
apply_<name>()    { validate_<name> "$1" || return 1; ...; notify "已切换<name>: $1"; }
loop_mode()       { while true; do select_<name>; apply_<name> "$X" || continue; done; }
main() { [ $# -ge 1 ] && apply_<name> "$1" || loop_mode; }
main "$@"
```

然后注册进 `settings/settings` 的 `get_settings_items` 与 `case`。

> **何时抽引擎库**：仅当套用逻辑要在**非 UI** 场景复用（如被 `bspwmrc` 调用）才抽到 `settings/lib/`，否则就近放在设置脚本里。详见 [设置菜单 → 新增设置项](settings.md#新增设置项)。

---

## 5. 新增一个布尔开关

**往 `settings/toggles/` 丢一个可执行脚本即可**，不碰菜单、不碰引擎。脚本实现三个子命令：

| 子命令 | 作用 |
|--------|------|
| `label` | 打印显示名 |
| `default` | 打印默认状态（`0`/`1`，缺省视为 `1`） |
| `apply <0\|1> [settle]` | 套用状态；`settle` 非空时用于骑过窗口重建 |

状态引擎、菜单 UI 都不用改。参考 `settings/toggles/dunst-pause.sh`。

> 完整机制见 [设置菜单 → 开关](settings.md#开关布尔设置)。

---

## 6. 新增一个主题

```bash
mkdir -p themes/colors/my-theme
# 写 colors.toml（照抄 themes/colors/nord/colors.toml 的字段）
~/.local/share/dotfiles/settings/setting-theme.sh my-theme
```

可选：加一张 `preview.jpg` 供菜单预览。主题由扫描 `themes/colors/` 自动发现。

> ⚠️ `.gitignore` 用 `desktop/*/colors.*` 忽略产物（不能用 `**/colors.*`，那会连主题源文件一起误伤）。只要产物落在 `desktop/<app>/` 下就自动覆盖；落到别处才需补规则。见 [ADR-0001](adr/0001-gitignore-colors-artifacts.md)。

---

## 7. 新增一个应用模板（让某应用跟随主题）

1. 建 `themes/templates/<app>.tpl`（用 `{{ 变量 }}` 占位）
2. 在 `themes/render.conf` 加一行：

```
应用|模板文件|输出路径|重载命令|标记
```

- 输出路径默认相对 `XDG_CONFIG_HOME`；前缀 `data:` 表示相对 `XDG_DATA_HOME`
- 标记加 `always` = 不判是否安装、始终渲染
- 不需要重载则第 4 列留空

3. 产物若落在 `desktop/<app>/` 下，`.gitignore` 已自动覆盖；落到别处才需补一条规则

> 变量与派生变量见 [主题系统](theming.md)。

---

## 8. 生效与验证

```bash
cd ~/.local/share/dotfiles
./install            # default
./install desktop    # default + desktop
./install rpi        # default + rpi
```

`./install` 会先 `clean` 掉指向本仓库的旧链接再重建，**幂等**，重复跑即更新。

**改完自检**：

```bash
# 所有 conf.d 声明的源文件都存在（改完路径后跑一次）
python3 - <<'EOF'
import yaml, glob, os
from pathlib import Path
bad=[]
for cf in Path('conf.d').glob('*.yaml'):
    for b in yaml.safe_load(cf.read_text()):
        if not isinstance(b,dict) or 'link' not in b: continue
        for t,s in b['link'].items():
            if isinstance(s,str): srcs=[s]
            elif isinstance(s,dict) and 'path' in s:
                p=s['path']; srcs=[p] if isinstance(p,str) else p
                if s.get('glob'): srcs=[x for q in srcs for x in glob.glob(q)]
            else: continue
            bad += [f"{cf.name}: {x}" for x in srcs if not os.path.exists(x)]
print("\n".join(bad) if bad else "全部源路径存在 ✓")
EOF
```

---

## 维护相关（非扩展）

Git 索引技巧、预览缓存、已知问题等维护者笔记见 [维护笔记](maintenance.md)。
