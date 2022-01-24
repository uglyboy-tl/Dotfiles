# environment variables
export DOTFILES="$HOME/.dotfiles"
export PATH=$PATH:$HOME/.local/bin

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Config of Plugin TMUX
ZSH_TMUX_AUTOSTART=true
ZSH_TMUX_DEFAULT_SESSION_NAME=ssh

# load zgen
source ~/.zgen/zgen.zsh

# Generate zgen init.sh if it doesn't exist
if ! zgen saved; then
    zgen oh-my-zsh

    # Plugins
    zgen oh-my-zsh plugins/git
    zgen oh-my-zsh plugins/git-auto-fetch
    zgen oh-my-zsh plugins/extract
    zgen oh-my-zsh plugins/debian
    zgen oh-my-zsh plugins/tmux
    zgen oh-my-zsh plugins/autojump
    zgen load zsh-users/zsh-syntax-highlighting

    # Theme
    zgen load romkatv/powerlevel10k powerlevel10k
   
    # Generate init.sh
    zgen save
fi  

source $DOTFILES/zsh/p10k.zsh

# alias definitions
# 查看文件夹大小
alias size='f(){ du -h --max-depth=1 $1 | sort -hr; }; f'
alias auto='systemctl list-unit-files --type=service | grep enabled | more'
alias cp='rsync -av --progress'
