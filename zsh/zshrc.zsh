# If you come from bash you might have to change your $PATH.
export PATH=$PATH:$HOME/.local/bin

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Allow local customizations in the ~/.zshrc_local_before file
[ ! -f ~/.zshrc.local.before ] || source ~/.zshrc.local.before

# environment variables
export DOTFILES="$HOME/.dotfiles"
export OS_RELEASE=`awk -F= '/^NAME/{print $2}' /etc/os-release | sed 's/"//g'`
export PYTHON_VENV_NAME=".venv"

# fzf options
export FZF_PREVIEW_COMMAND="bat --style=numbers,header --color=always {} || batcat --style=numbers,header --color=always {} || cat {}"
export FZF_DEFAULT_OPTS="--height 50% --preview-window right:60% --layout=reverse --preview '($FZF_PREVIEW_COMMAND) 2> /dev/null'"
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!{.git,.idea,.vscode,.sass-cache,node_modules,build,.m2}/*" 2> /dev/null'
export FZF_ALT_C_COMMAND="rg --sort-files --files --null 2> /dev/null | xargs -0 dirname | uniq"

# load zgen
source ~/.zgen/zgen.zsh

# Generate zgen init.sh if it doesn't exist
if ! zgen saved; then
    zgen oh-my-zsh

    # Plugins
    zgen oh-my-zsh plugins/git
    zgen oh-my-zsh plugins/git-auto-fetch
    zgen oh-my-zsh plugins/extract
    case ${OS_RELEASE} in
        "Ubuntu" )
            zgen oh-my-zsh plugins/ubuntu
            ;;
        "Raspbian GNU/Linux" )
            zgen oh-my-zsh plugins/ubuntu
            ;;
        "Debian GNU/Linux" )
            zgen oh-my-zsh plugins/ubuntu
            ;;
        "Arch Linux" )
            zgen oh-my-zsh plugins/archlinux
            ;;
        "Arch Linux ARM" )
            zgen oh-my-zsh plugins/archlinux
            ;;
        * )
            echo "other"
            ;;
    esac
    zgen oh-my-zsh plugins/cp
    zgen oh-my-zsh plugins/zoxide
    zgen oh-my-zsh plugins/fzf
    zgen oh-my-zsh plugins/poetry
    zgen load zsh-users/zsh-syntax-highlighting
    zgen load marlonrichert/zsh-autocomplete

    [ ! -f ~/.zshrc.local.zgen ] || source ~/.zshrc.local.zgen

    # Theme
    zgen load romkatv/powerlevel10k powerlevel10k

    # Generate init.sh
    zgen save
fi

#source $DOTFILES/zsh/p10k.zsh

# alias definitions
alias size='f(){ du -h --max-depth=1 $1 | sort -hr; }; f'
alias slideshow='feh -rzqFZYD 5'
alias auto='systemctl list-unit-files --type=service | grep enabled | more'
alias runv='source .venv/bin/activate'
#alias cp='rsync -av --progress'
# replaced command
alias duf='duf --only local'

# Allow local customizations in the ~/.zshrc_local_after file
[ ! -f ~/.zshrc.local.after ] || source ~/.zshrc.local.after

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

test -r ~/.dir_colors && eval $(dircolors ~/.dir_colors)
setopt no_nomatch
