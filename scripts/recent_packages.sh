#!/bin/bash
# 最近安装/卸载的软件包分析脚本

set -euo pipefail

# 默认参数
DAYS=7
APT_LOG="/var/log/apt/history.log"
SHOW_AUTO=0  # 0=只显示手动, 1=显示所有
SHOW_REMOVED=0  # 0=显示已安装, 1=显示已卸载

show_help() {
    cat << EOF
用法: $0 [选项]

选项:
  -d DAYS         分析最近多少天的记录 (默认: 7)
  -l FILE         apt 日志文件路径 (默认: /var/log/apt/history.log)
  -a              显示自动安装的包（默认只显示手动安装的）
  -r              显示已卸载的包（默认显示已安装的包）
  -h              显示此帮助信息

示例:
  $0 -d 7         分析最近7天安装的手动包
  $0 -d 14        分析最近14天安装的手动包
  $0 -d 7 -a      分析最近7天安装的所有包（包括自动安装的）
  $0 -d 7 -r      分析最近7天卸载的包
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -d)
            DAYS="$2"
            shift 2
            ;;
        -l)
            APT_LOG="$2"
            shift 2
            ;;
        -a)
            SHOW_AUTO=1
            shift
            ;;
        -r)
            SHOW_REMOVED=1
            shift
            ;;
        -h)
            show_help
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

if [[ ! -f "$APT_LOG" ]]; then
    echo "错误: 找不到 apt 日志文件: $APT_LOG"
    exit 1
fi

# 计算开始日期
START_DATE=$(date -d "-${DAYS} days" +"%Y-%m-%d" 2>/dev/null || echo "1970-01-01")

if [[ $SHOW_REMOVED -eq 1 ]]; then
    # ========== 显示已卸载的包 ==========
    echo "分析最近 ${DAYS} 天的卸载记录..."
    echo "开始日期: $START_DATE"
    echo ""
    echo "已卸载的软件包:"
    echo "=============="

    # 提取卸载的包并验证当前是否已卸载
    mawk -v start_date="$START_DATE" '
    BEGIN {
        # 获取当前已安装的包列表
        while (("dpkg -l" | getline line) > 0) {
            # dpkg -l 格式: ii  pkg-name  version  ...
            if (line ~ /^ii  [a-z]/) {
                split(line, fields)
                pkg_name = fields[2]
                # 去掉架构后缀
                sub(/:[a-z0-9]+$/, "", pkg_name)
                installed[pkg_name] = 1
            }
        }
        close("dpkg -l")
    }

    /^Start-Date:/ { date = $2 }

    /^(Purge:|Remove:)/ {
        line = $0
        sub(/^(Purge:|Remove:)[ \t]*/, "", line)
        n = split(line, parts, ",")
        for (i = 1; i <= n; i++) {
            pkg = parts[i]
            gsub(/^[ \t]+|[ \t]+$/, "", pkg)
            if (pkg == "") continue
            gsub(/ \([0-9][^)]*\)/, "", pkg)
            if (pkg == "") continue
            sub(/:[a-z0-9]+$/, "", pkg)
            # 只记录指定日期之后的卸载，且当前已卸载
            if (date >= start_date && !(pkg in installed)) {
                removed[pkg] = date
            }
        }
    }

    END {
        for (pkg in removed) {
            printf "%-40s %s\n", pkg, removed[pkg]
        }
    }
    ' "$APT_LOG" | sort -k2,2 -k1

else
    # ========== 显示已安装的包（原有逻辑） ==========
    echo "分析最近 ${DAYS} 天的安装记录..."
    echo "开始日期: $START_DATE"
    echo ""
    echo "安装的软件包:"
    echo "=============="

    # 提取安装的包（自动过滤已卸载的）
    mawk -v start_date="$START_DATE" -v show_auto="${SHOW_AUTO:-0}" '
    BEGIN {
        delete installed
        delete is_auto
    }

    /^Start-Date:/ { date = $2 }

    /^Install:/ {
        line = substr($0, 9)
        gsub(/ \([0-9][^)]*, automatic\)/, " PLACEHOLDER_AUTO", line)
        gsub(/ \([0-9][^)]*\)/, " PLACEHOLDER_MANUAL", line)
        n = split(line, parts, ",")
        for (i = 1; i <= n; i++) {
            pkg = parts[i]
            gsub(/^[ \t]+|[ \t]+$/, "", pkg)
            if (pkg == "") continue
            
            auto = 0
            if (pkg ~ /PLACEHOLDER_AUTO/) {
                auto = 1
                gsub(/ PLACEHOLDER_AUTO$/, "", pkg)
            } else {
                gsub(/ PLACEHOLDER_MANUAL$/, "", pkg)
            }
            
            if (pkg == "") continue
            sub(/:[a-z0-9]+$/, "", pkg)
            
            if (date >= start_date) {
                installed[pkg] = date
                is_auto[pkg] = auto
            }
        }
    }

    /^(Purge:|Remove:)/ {
        line = $0
        sub(/^(Purge:|Remove:)[ \t]*/, "", line)
        n = split(line, parts, ",")
        for (i = 1; i <= n; i++) {
            pkg = parts[i]
            gsub(/^[ \t]+|[ \t]+$/, "", pkg)
            if (pkg == "") continue
            gsub(/ \([0-9][^)]*\)/, "", pkg)
            if (pkg == "") continue
            sub(/:[a-z0-9]+$/, "", pkg)
            delete installed[pkg]
            delete is_auto[pkg]
        }
    }

    END {
        for (pkg in installed) {
            if (show_auto || !is_auto[pkg]) {
                marker = ""
                if (is_auto[pkg]) marker = " (自动)"
                printf "%s %s%s\n", pkg, installed[pkg], marker
            }
        }
    }
    ' "$APT_LOG" | sort -k2,2 -k1 | awk -F' ' '{printf "%-40s %s%s\n", $1, $2, $3}'
fi

echo ""
echo "完成!"

show_help() {
    cat << EOF
用法: $0 [选项]

选项:
  -d DAYS         分析最近多少天的记录 (默认: 7)
  -l FILE         apt 日志文件路径 (默认: /var/log/apt/history.log)
  -a              显示自动安装的包（默认只显示手动安装的）
  -r              显示已卸载的包（默认显示已安装的包）
  -h              显示此帮助信息

示例:
  $0 -d 7         分析最近7天安装的手动包
  $0 -d 14        分析最近14天安装的手动包
  $0 -d 7 -a      分析最近7天安装的所有包（包括自动安装的）
  $0 -d 7 -r      分析最近7天卸载的包

说明:
  默认只显示当前仍然安装且手动安装的包。
  使用 -a 参数可显示所有包（包括自动安装的依赖）。
  已卸载的包会被自动过滤。
  使用 -r 参数可查看已卸载的包（会验证当前是否真的已卸载）。
EOF
}
