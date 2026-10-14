# 系统软件包与消费者

本机 Debian 13 (trixie) 的 apt 包分四类。**要点**：`apt-mark showmanual` 里的条目多半不是「手动装的」，而是第三方 deb 捎带或自建软件的运行时；反过来，有些包虽是 `auto`，却承载着系统运行。改 `apt-mark` / 跑 `apt autoremove` 前先对表。

## 怎么判断一个包能不能降 auto

`apt-cache rdepends` 只看得见**包与包**的关系，看不见两类消费者，所以三处一起查：

1. **已装包反向依赖**：`apt-cache rdepends --installed --no-recommends --no-suggests <pkg>`
2. **自建/手解压的程序**：`ldd <二进制> | grep <soname>`
3. **dlopen 型插件**（Qt / GStreamer / SDL / Chromium）：`grep -rlI --binary-files=text '<soname>' <目录>`，或直接看 `uxplay --help` 这类文档说明

预演与回滚：

```sh
sudo apt-mark auto <pkg> && sudo apt autoremove --dry-run && sudo apt-mark manual <pkg>
```

apt 默认 `RecommendsImportant=true`、`SuggestsImportant=true`：**Recommends / Suggests 也会保护包不被 autoremove**（`gstreamer1.0-plugins-bad` 靠 uxplay 的 Recommends 保命，`xvfb` 靠某个 Suggests 链保命）。所以「降 auto」在多数情况下只是表态，真删要等上游 Recommends/Suggests 消失。

**当前状态（2026-10-13）**：A 组 18 + B 组 9 个包已降 `auto`，`sudo apt autoremove --dry-run` 只剩 **2 个字体**会被删（`fonts-tlwg-loma-otf`、`fonts-unifont`），其余都被上面的保护机制或 `NeverAutoRemove`（`firmware-linux-free`）挡住。

## A. 必须保持 manual（有活消费者）

降 auto 后 `apt autoremove` 会真删，对应功能随即坏掉。

| 包 | 消费者 | 证据 |
|---|---|---|
| `steam-libs-amd64`、`steam-libs-i386:i386` | Steam 客户端的 32 位运行库链 | 只是 `steam-launcher` 的 **Recommends**，rdepends 为空；降 auto 会连带删掉 `libc6:i386`/`libgl1:i386` 等，Steam 直接起不来 |
| `libqt6multimedia6`、`libenet7`、`libqt6widgets6` | `/mnt/data/Games/melonDS`（DS 模拟器，手动解压） | `ldd` 直接 NEEDED（另有 `libfaad2`、`libSDL2-2.0.so.0`） |
| `libsdl2-image-2.0-0`、`libsdl2-mixer-2.0-0`、`libsdl2-ttf-2.0-0`、`libsquish0`、`libfmt10`、`libtbb12`、`libminizip1t64`、`libboost-iostreams1.83.0`、`libqt6widgets6` | `~/Code/vcmi` 的源码构建（`build/bin/vcmi{client,launcher,editor,server}`） | `ldd` 直接 NEEDED；2026-08-28 明确为它装过一批 |
| `gstreamer1.0-gl` | uxplay（AirPlay 镜像） | uxplay 的 Recommends；gstgl sink 由 GStreamer 运行时 dlopen，rdepends 查不到 |
| `libfaad2`（当前为 `auto`） | melonDS + `gstreamer1.0-plugins-bad` | `ldd` melonDS + `rdepends`；靠 uxplay→plugins-bad 的 Recommends 链保住，**别把 uxplay 降 auto** |
| `fonts-wqy-zenhei`、`fonts-noto-color-emoji` | 中文 / emoji 显示，明确要保留 | — |
| `librime-plugin-lua` | fcitx5-rime 的 lua 插件 | — |

> **自建 vcmi 的已知缺口**：`vcmieditor` 还缺 `libqt6xml6`、`libqt6svg6`、`libqt6svgwidgets6`（2026-08-28 10:16 被 purge），跑不起来。地图编辑器不用，**有意不补装**；client / server / launcher 正常。

## B. 第三方 deb 捎带（正常现象，别去「清理」）

`microsoft-edge-stable`、`code`、`bytedance-feishu-stable`、`motrix-next`、`obsidian`、`wechat`、`opencode`、`rtk` 等第三方 deb 会把自身依赖留成 manual（含 i18n 字体、Electron 运行库、tmux/rofi 框架插件等）。这些条目出现在 `showmanual` 里属预期，不必逐个降级。

## C. 叶子包（无消费者，已降 auto）

2026-06-15 一批为 Electron / Chromium 无头依赖装的包，现在已无调用者（dotfiles 无 `Xvfb` 引用，`~/.cache/ms-playwright` 为空）：

`xvfb`、`xfonts-scalable`、`fonts-unifont`、`fonts-ipafont-gothic`、`fonts-tlwg-loma-otf`、`firmware-linux-free`

已降 `auto`（2026-10-13）。实际会被 autoremove 删的只有 `fonts-tlwg-loma-otf`、`fonts-unifont`，其余被 Recommends/Suggests 链或 `NeverAutoRemove` 护住。留着只多占几 MB。

## D. 有 dpkg 反向依赖（已降 auto）

已降 `auto`（2026-10-13），不会被 autoremove 删。

| 包 | 谁依赖它 |
|---|---|
| `libatk-bridge2.0-0t64` | `libgtk-3-0t64` |
| `libcups2t64` | `libgtk-3-0t64`、`libgtk-4-1`、`libgs10` |
| `fonts-freefont-ttf` | `fontconfig-config`（Recommends） |

## 已知坑

- **第三方 deb 的 postrm 可能缺 debconf**：`trae-cn`（微软系打包）的 postrm 调 `db_purge` 却从未 source `/usr/share/debconf/confmodule`，purge 时 dpkg 报 `db_purge: 未找到命令`、退出码 127，包卡在 `ic` 状态反复失败。解法：`sudo mv /var/lib/dpkg/info/trae-cn.postrm /tmp/` 再 `sudo dpkg --purge trae-cn`（脚本挪走后 dpkg 无脚本可跑）。
- **purge 前查锁**：autoremove / unattended-upgrade / 第三方 deb 安装都可能占着 dpkg 锁，撞上直接失败。`sudo fuser -v /var/lib/dpkg/lock-frontend` 看持有者，等它结束再重试（别硬删锁文件）。
- **`linux-image-*` 在 `NeverAutoRemove` 里**：`autoremove` 永远不会碰它们，降级余地要主动清就得 `apt purge`。

## 会拉系统库的非 apt 内容

- **Steam**：Valve 仓库的 `steam-launcher` + `steam-libs-*`；游戏库在 `/mnt/data/SteamLibrary`（Divinity OS2 / Grim Dawn / Witcher 3 为原生 Linux，其余走 Proton）。原生游戏跑 **Steam Linux Runtime**（`SteamLinuxRuntime_sniper`/`soldier`，宿主 `~/.local/share/Steam/steamrt3/`），自带 SDL2 / tbb / atk-bridge / cups，**不需要**宿主同名库。
- **`/mnt/data/Games/`**：`melonDS`（Qt6 + SDL2 + enet + faad2）、`sdlpal`（静态链接，无库依赖）、`battlenet/`（Lutris + Wine，用 `~/.local/share/lutris/runners/` 自带运行时）、`modorganizer2`。
- **`~/Code/vcmi`**：源码构建的游戏本体（见 A 组）。
- **uxplay**：AirPlay 镜像，走 GStreamer（`plugins-bad`、`libfaad2`、`gstreamer1.0-gl`）。

## 手动清单快照

`/mnt/back/manual-backup.txt` 是 `apt-mark showmanual` 的某次快照（目录 root 所有，写入需 sudo）：

```sh
apt-mark showmanual | sort > /tmp/manual-backup.new
sudo cp /tmp/manual-backup.new /mnt/back/manual-backup.txt
sudo chown uglyboy:uglyboy /mnt/back/manual-backup.txt
```

## 相关

- 软件配置路径见 [软件与配置路径](software.md)
- 仓库级约定与清理流程见 [维护笔记](../maintenance.md)
