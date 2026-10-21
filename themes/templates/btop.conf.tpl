# btop 配置（由 themes/templates/btop.conf.tpl 渲染，勿手改）
# 注意：btop 退出时会把整份配置回写（值保留，注释会被替换成它自己的英文注释），
# 所以真要改设置就改这个模板，改完重渲染或换一次主题即生效。
# 用途定位：终端里看硬件整体状态，进程详情基本交给 agent，所以默认不显示进程框。

# 主题文件由同一个渲染流程生成到 ~/.config/btop/themes/dotfiles.theme
color_theme = "dotfiles"

# 背景用主题背景色（与终端同色，视觉无缝）；想让终端背景透出来就改 False
theme_background = True
truecolor = True
force_tty = False

# 预设 1 = 纯硬件指标（cpu/mem/net），预设 2 = 进程视角；启动时用最近一次的布局
# 1.3.2 没有独立 gpu 方框（写 gpu: 会被忽略并退化成只剩 proc），GPU 占用与温度显示在 cpu 框内，
# 由下面的 show_gpu_info 控制。
presets = "cpu:0:default,mem:0:default,net:0:default cpu:0:default,proc:0:default"

# 首次渲染后的默认布局：不含进程框
shown_boxes = "cpu mem net"

# 习惯 vim 的 hjkl 导航
vim_keys = True

rounded_corners = True

# braille 分辨率最高；字体缺字形时退回 block
graph_symbol = "braille"
graph_symbol_cpu = "default"
graph_symbol_gpu = "default"
graph_symbol_mem = "default"
graph_symbol_net = "default"
graph_symbol_proc = "default"

# 刷新间隔 1s：比默认 2s 顺滑，又不会明显吃 CPU
update_ms = 1000

# 上排画总占用，下排自动（有 GPU 时即 GPU）；GPU 一行常显
cpu_graph_upper = "total"
cpu_graph_lower = "Auto"
show_gpu_info = "On"
cpu_invert_lower = True
cpu_single_graph = False
cpu_bottom = False

show_uptime = True
check_temp = True
cpu_sensor = "Auto"
show_coretemp = True
temp_scale = "celsius"
base_10_sizes = False
show_cpu_freq = True

# 与 polybar 的 12 小时制保持一致（想要纯中文日期可改 "%c"）
clock_format = "%I:%M %p"

background_update = True

mem_graphs = True
mem_below_net = False
# mem 框里保留 swap 用量，但磁盘列表不单列 swap 分区（行内注释会被 btop 当成值的一部分，勿用）
show_swap = True
swap_disk = False

# 磁盘只显示物理设备，带 IO% 与使用率。
# disks_filter 只留真正关心的挂载点（空格分隔的包含列表）：/boot、/opt、/mnt/back 不进视野，
# 否则列表比 mem 框还长，一眼看不完。
# 【本机专属】disks_filter 与 net_iface 写的是这台机器的挂载点与网卡（eno1），
# 换机器（含 rpi）要在这里改；btop 没有 include/override 机制，只能改模板。
show_disks = True
only_physical = True
use_fstab = True
disks_filter = "/ /home /mnt/data /mnt/ssd"
show_io_stat = True
io_mode = False

# 固定到有线网卡，避免 docker/veth 之类虚拟接口混进来（本机专属，见上）；刻度自适应
net_download = 100
net_upload = 100
net_auto = True
net_sync = True
net_iface = "eno1"

# 进程框只在预设 2 出现；按 CPU 做 lazy 排序，隐藏内核线程
proc_sorting = "cpu lazy"
proc_reversed = False
proc_tree = False
proc_colors = True
proc_gradient = True
proc_per_core = False
proc_mem_bytes = True
proc_cpu_graphs = True
proc_info_smaps = False
proc_left = False
proc_filter_kernel = True

show_battery = True
show_battery_watts = True

nvml_measure_pcie_speeds = True
gpu_mirror_graph = True

log_level = "WARNING"
