# ──────────────────────────────────────────────
# Powerlevel10k 即时提示（必须最顶部）
# ──────────────────────────────────────────────
if [[ -z "$TMUX" && -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ──────────────────────────────────────────────
# 基础环境变量
# ──────────────────────────────────────────────
# path 是 PATH 的关联数组：-U 开启去重，赋值时自动丢掉重复项。
# 必须用数组式赋值才生效（字符串式 PATH=... 不去重），目的是不让嵌套 shell
# 反复前置同一目录把 PATH 越堆越长。
typeset -U path
path=($HOME/.local/bin $path)
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
export ZLOCAL="${XDG_CONFIG_HOME:-$HOME/.config}/local"
export DOTFILES="$XDG_DATA_HOME/dotfiles"
export OS_RELEASE="${OS_RELEASE:-$(source /etc/os-release 2>/dev/null && echo $NAME)}"
export PYTHON_VENV_NAME=".venv"
export ZSH_WAKATIME_PROJECT_DETECTION=true

# ──────────────────────────────────────────────
# 历史记录
# ──────────────────────────────────────────────
export HISTFILE=$XDG_STATE_HOME/zsh/history
export HISTSIZE=100000
export SAVEHIST=100000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

# ──────────────────────────────────────────────
# FZF 配置
# ──────────────────────────────────────────────
export FZF_PREVIEW_COMMAND="bat --style=numbers,header --color=always {} || batcat --style=numbers,header --color=always {} || cat {}"
export FZF_DEFAULT_OPTS=" \
--color=16,border:gray,label:gray \
--color=hl:blue,hl+:reverse:blue \
--color=pointer:cyan,spinner:cyan,marker:cyan \
--color=info:yellow,prompt:yellow \
--height 50% --preview-window right:60% --layout=reverse --preview '($FZF_PREVIEW_COMMAND) 2> /dev/null'"
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!{.git,.idea,.vscode,.sass-cache,node_modules,build,.m2}/*" 2> /dev/null'
export FZF_ALT_C_COMMAND="rg --sort-files --null --files 2> /dev/null | xargs -0 dirname | sort -u"

# ──────────────────────────────────────────────
# 本地覆盖（before）
# ──────────────────────────────────────────────
[ -f "$ZLOCAL/zshrc.before" ] && source "$ZLOCAL/zshrc.before"

# 自动建议默认每个 prompt 重绑 ~210 个 ZLE widget（实测约 18ms/次）。
# 关掉后只在启动时绑一次；若日后新增会包装 ZLE widget 的插件，删掉这行。
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# ──────────────────────────────────────────────
# Zinit 插件管理
# ──────────────────────────────────────────────
source "${ZDOTDIR:-$HOME/.config/zsh}/zinit/zinit.zsh"

# 同步加载：补全系统（compinit 依赖）
zi snippet OMZL::completion.zsh

# 补全定义库：必须在 compinit（turbo 批里的 zicompinit）之前加载，
# 否则新补全不会被 compinit 收录。插件自带文件只做 fpath+=src，不带 compinit。
zi light zsh-users/zsh-completions

# 本地插件列表
[ -f "$ZLOCAL/zshrc.plugins" ] && source "$ZLOCAL/zshrc.plugins"

# Turbo 延迟加载：OMZ 基础模块 + 语法高亮 + 常用插件
zi wait lucid for \
  OMZL::key-bindings.zsh \
  OMZL::directories.zsh \
  OMZL::history.zsh \
  atinit'zicompinit; zicdreplay' \
    zdharma-continuum/fast-syntax-highlighting \
  atload'_zsh_autosuggest_start' \
    zsh-users/zsh-autosuggestions \
  OMZP::extract \
  OMZP::zoxide \
  OMZP::fzf

# 平台特定插件
case "$OS_RELEASE" in
  "Ubuntu"|"Raspbian GNU/Linux"|"Debian GNU/Linux")
    zi ice wait lucid; zi snippet OMZP::ubuntu
    ;;
  "Arch Linux"|"Arch Linux ARM")
    zi ice wait lucid; zi snippet OMZP::archlinux
    ;;
esac

# ──────────────────────────────────────────────
# 主题与提示符
# ──────────────────────────────────────────────
zi ice depth=1; zi light romkatv/powerlevel10k

# ──────────────────────────────────────────────
# 别名与本地覆盖（after）
# ──────────────────────────────────────────────
[ -f "$ZDOTDIR/zshrc.alias" ] && source "$ZDOTDIR/zshrc.alias"
[ -f "$ZDOTDIR/zshrc.rpi" ] && source "$ZDOTDIR/zshrc.rpi"
[ -f "$ZLOCAL/zshrc.after" ] && source "$ZLOCAL/zshrc.after"

# ──────────────────────────────────────────────
# 工具初始化
# ──────────────────────────────────────────────
setopt no_nomatch
# Ctrl-r 让给 fzf（OMZP::fzf 后加载会覆盖 atuin，这里显式关掉 atuin 的绑定避免两套互抢）
eval "$(atuin init zsh --disable-ctrl-r --disable-up-arrow)"

# ──────────────────────────────────────────────
# Powerlevel10k 配置
# ──────────────────────────────────────────────
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
