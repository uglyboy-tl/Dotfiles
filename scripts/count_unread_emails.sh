#!/bin/bash

# 设置你的邮件目录的路径，这里以 "~/Maildir" 为例
# 如果你有多个账户，可能需要为每个账户设置并检查
MAILDIR=~/.Mail

# 计算未读邮件的数量
# Maildir格式中，未读邮件位于 "new" 目录中
# 使用 find 命令来计数 "new" 目录下的文件数量
UNREAD_COUNT=$(find "$MAILDIR"/ -type f -wholename "*/new/*" | wc -l)

# 输出未读邮件的数量
echo "$UNREAD_COUNT"