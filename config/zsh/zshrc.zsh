#!/bin/bash

export PATH="$HOME/.local/bin:$PATH"
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
export ZLOCAL="${XDG_CONFIG_HOME:-$HOME/.config}/local"
export HISTFILE=$XDG_STATE_HOME/zsh/history
export ZSH_DISABLE_COMPFIX=true

[ -f "$ZLOCAL/zshrc.before" ] && source "$ZLOCAL/zshrc.before"

export DOTFILES="$XDG_DATA_HOME/dotfiles"
export OS_RELEASE=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')
export PYTHON_VENV_NAME=".venv"

# fzf options
export FZF_PREVIEW_COMMAND="bat --style=numbers,header --color=always {} || batcat --style=numbers,header --color=always {} || cat {}"
export FZF_DEFAULT_OPTS=" \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=selected-bg:#45475A \
--color=border:#6C7086,label:#CDD6F4 \
--height 50% --preview-window right:60% --layout=reverse --preview '($FZF_PREVIEW_COMMAND) 2> /dev/null'"
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!{.git,.idea,.vscode,.sass-cache,node_modules,build,.m2}/*" 2> /dev/null'
export FZF_ALT_C_COMMAND="rg --sort-files --files --null 2> /dev/null | xargs -0 dirname | uniq"

export ZGEN_DIR="$ZDOTDIR/zgen"
source "$ZGEN_DIR/zgen.zsh"

export ZSH_WAKATIME_PROJECT_DETECTION=true

# Generate zgen init.sh if it doesn't exist
if ! zgen saved; then
    zgen oh-my-zsh
    zgen oh-my-zsh plugins/git-auto-fetch
    zgen oh-my-zsh plugins/extract
    case "$OS_RELEASE" in
        "Ubuntu"|"Raspbian GNU/Linux"|"Debian GNU/Linux")
            zgen oh-my-zsh plugins/ubuntu
            ;;
        "Arch Linux"|"Arch Linux ARM")
        zgen oh-my-zsh plugins/archlinux
            ;;
        *)
            ;;
        esac

    zgen oh-my-zsh plugins/zoxide
    zgen oh-my-zsh plugins/fzf
    zgen load zsh-users/zsh-syntax-highlighting
    zgen load wbingli/zsh-wakatime

    [ -f "$ZLOCAL/zshrc.plugins" ] && source "$ZLOCAL/zshrc.plugins"

    zgen save
fi

compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

[ -f "$ZDOTDIR/zshrc.alias" ] && source "$ZDOTDIR/zshrc.alias"
[ -f "$ZLOCAL/zshrc.after" ] && source "$ZLOCAL/zshrc.after"

setopt no_nomatch

eval "$(starship init zsh)"