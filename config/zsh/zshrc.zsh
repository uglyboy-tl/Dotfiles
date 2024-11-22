# If you come from bash you might have to change your $PATH.
export PATH=$HOME/.local/bin:$PATH
[ ! -f ${XDG_CONFIG_HOME:-$HOME/.config}/environment ] || source ${XDG_CONFIG_HOME:-$HOME/.config}/environment
export ZDOTDIR=${ZDOTDIR:-$HOME/.config/zsh}

export ZSH_DISABLE_COMPFIX=true

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# Allow local customizations in the ~/.zshrc_local_before file
[ ! -f $ZDOTDIR/before ] || source $ZDOTDIR/before

# environment variables
export DOTFILES="$XDG_DATA_HOME/dotfiles"
export OS_RELEASE=`awk -F= '/^NAME/{print $2}' /etc/os-release | sed 's/"//g'`
export PYTHON_VENV_NAME=".venv"

# fzf options
export FZF_PREVIEW_COMMAND="bat --style=numbers,header --color=always {} || batcat --style=numbers,header --color=always {} || cat {}"
export FZF_DEFAULT_OPTS="--height 50% --preview-window right:60% --layout=reverse --preview '($FZF_PREVIEW_COMMAND) 2> /dev/null'"
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!{.git,.idea,.vscode,.sass-cache,node_modules,build,.m2}/*" 2> /dev/null'
export FZF_ALT_C_COMMAND="rg --sort-files --files --null 2> /dev/null | xargs -0 dirname | uniq"

# load zgen
export ZGEN_DIR=$ZDOTDIR/zgen
source $ZGEN_DIR/zgen.zsh

# Generate zgen init.sh if it doesn't exist
if ! zgen saved; then
    zgen oh-my-zsh

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
    zgen load zsh-users/zsh-syntax-highlighting

    # Plugins
    [ ! -f $ZDOTDIR/plugins ] || source $ZDOTDIR/plugins

    # Theme
    zgen load romkatv/powerlevel10k powerlevel10k

    # Generate init.sh
    zgen save
fi

compinit -d "$XDG_CACHE_HOME"/zsh/zcompdump-"$ZSH_VERSION"
#source $DOTFILES/zsh/p10k.zsh

# alias definitions
alias size='f(){ sudo du -h --max-depth=1 $1 | sort -hr; }; f'
alias runv='source .venv/bin/activate'

# replaced command
alias duf='duf --only local'
alias wget=wget --hsts-file="$XDG_DATA_HOME/wget-hsts"

# Allow local customizations in the ~/.zshrc_local_after file
[ ! -f $ZDOTDIR/after ] || source $ZDOTDIR/after

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f $ZDOTDIR/p10k.zsh ]] || source $ZDOTDIR/p10k.zsh

setopt no_nomatch