#!/usr/bin/env bash

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH="$HOME/.local/bin:$PATH"
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
export ZLOCAL="${XDG_CONFIG_HOME:-$HOME/.config}/local"

# History settings
export HISTFILE=$XDG_STATE_HOME/zsh/history
export DOTFILES="$XDG_DATA_HOME/dotfiles"
export OS_RELEASE="${OS_RELEASE:-$(source /etc/os-release 2>/dev/null && echo $NAME)}"
export PYTHON_VENV_NAME=".venv"

[ -f "$ZLOCAL/zshrc.before" ] && source "$ZLOCAL/zshrc.before"

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

source "${ZDOTDIR:-$HOME/.config/zsh}/zinit/zinit.zsh"

export ZSH_WAKATIME_PROJECT_DETECTION=true

# Load Oh My Zsh basic functionality
zi snippet OMZL::completion.zsh
zi snippet OMZL::key-bindings.zsh
zi snippet OMZL::directories.zsh
zi snippet OMZL::history.zsh
zi snippet OMZL::correction.zsh
zi snippet OMZL::functions.zsh
zi snippet OMZL::termsupport.zsh
zi snippet OMZL::spectrum.zsh
zi snippet OMZL::theme-and-appearance.zsh

# Load Oh My Zsh plugins
zi snippet OMZP::git-auto-fetch
zi snippet OMZP::extract
zi snippet OMZP::zoxide
zi snippet OMZP::fzf

case "$OS_RELEASE" in
  "Ubuntu"|"Raspbian GNU/Linux"|"Debian GNU/Linux")
    zi snippet OMZP::ubuntu
    ;;
  "Arch Linux"|"Arch Linux ARM")
    zi snippet OMZP::archlinux
    ;;
  *)
    ;;
esac


[ -f "$ZLOCAL/zshrc.plugins" ] && source "$ZLOCAL/zshrc.plugins"

# Enable autosuggestions and syntax highlighting with zinit's turbo mode for faster startup
zinit wait lucid for \
  atinit'zicompinit; zicdreplay' \
    zdharma-continuum/fast-syntax-highlighting \
  atload'_zsh_autosuggest_start' \
    zsh-users/zsh-autosuggestions \

# Load powerlevel10k theme last for better performance
zi ice depth=1; zi light romkatv/powerlevel10k

[ -f "$ZDOTDIR/zshrc.alias" ] && source "$ZDOTDIR/zshrc.alias"
[ -f "$ZLOCAL/zshrc.after" ] && source "$ZLOCAL/zshrc.after"

setopt no_nomatch

eval "$(atuin init zsh --disable-up-arrow)"

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
