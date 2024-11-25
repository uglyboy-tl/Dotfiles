# 从指定的URL或文件中获取内容
fetch_content() {
    # 检查参数数量是否正确
    if [ "$#" -ne 1 ]; then
        echo "Usage: fetch_content <url_or_file>"
        return 1
    fi

    local input="$1"
    # 如果输入是一个URL，则使用curl获取内容
    if [[ "$input" =~ ^https?:// ]]; then
        curl -s "https://r.jina.ai/$input"
    # 如果输入是一个可读文件，则使用cat获取内容
    elif [[ -f "$input" && -r "$input" ]]; then
        cat "$input"
    # 如果输入既不是URL也不是文件，则直接输出输入内容
    else
        echo "$input"
    fi
}


# fabric
summarize(){ fetch_content "$1" | fabric -p summarize -s; }
alias summarize='f(){curl -s "https://r.jina.ai/$1" | fabric -p summarize -s;}; f'