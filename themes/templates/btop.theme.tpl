# btop 主题（由 themes/templates/btop.theme.tpl 渲染，勿手改；换主题走 settings → 主题）
# 只引用主题的 16 色与派生色，8 套主题自动跟随，无需为 btop 单独配色。
# 配色意图：方框标题用 accent 区分大类；温度走 绿→黄→红；CPU 走 青→蓝→紫（冷色，避免和温度撞）；
# 内存/磁盘用 紫→蓝→青；代表消耗的 used 与上传走 橙→红。

# 主背景与文字
theme[main_bg]="{{ background }}"
theme[main_fg]="{{ foreground }}"

# 方框标题、快捷键高亮
theme[title]="{{ accent }}"
theme[hi_fg]="{{ accent }}"

# 选中项（进程列表）：前景跟主题的 selection_foreground，浅色 selection（如 catppuccin）才可读
theme[selected_bg]="{{ selection }}"
theme[selected_fg]="{{ selection_foreground }}"

# 失效/次要文字
theme[inactive_fg]="{{ muted }}"

# 进程框内的小图与状态文字
theme[proc_misc]="{{ green }}"

# 四个方框的描边色（按语义区分，比统一描边更好定位）
theme[cpu_box]="{{ accent }}"
theme[mem_box]="{{ green }}"
theme[net_box]="{{ magenta }}"
theme[proc_box]="{{ cyan }}"

# 分隔线
theme[div_line]="{{ selection }}"

# 温度：绿 → 黄 → 红
theme[temp_start]="{{ green }}"
theme[temp_mid]="{{ yellow }}"
theme[temp_end]="{{ red }}"

# CPU：青 → 蓝 → 紫
theme[cpu_start]="{{ cyan }}"
theme[cpu_mid]="{{ accent }}"
theme[cpu_end]="{{ magenta }}"

# 内存/磁盘 空闲
theme[free_start]="{{ magenta }}"
theme[free_mid]="{{ accent }}"
theme[free_end]="{{ cyan }}"

# 内存/磁盘 缓存
theme[cached_start]="{{ cyan }}"
theme[cached_mid]="{{ accent }}"
theme[cached_end]="{{ magenta }}"

# 内存/磁盘 可用
theme[available_start]="{{ green }}"
theme[available_mid]="{{ cyan }}"
theme[available_end]="{{ accent }}"

# 内存/磁盘 已用
theme[used_start]="{{ orange }}"
theme[used_mid]="{{ orange }}"
theme[used_end]="{{ red }}"

# 网络 下载（绿 → 青）、上传（橙 → 红）
theme[download_start]="{{ green }}"
theme[download_mid]="{{ cyan }}"
theme[download_end]="{{ accent }}"

theme[upload_start]="{{ orange }}"
theme[upload_mid]="{{ orange }}"
theme[upload_end]="{{ red }}"
