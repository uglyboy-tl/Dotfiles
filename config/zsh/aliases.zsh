# alias definitions
alias size='f(){ sudo du -h --max-depth=1 $1 | sort -hr; }; f'
alias runv='source .venv/bin/activate'
alias mc='mc -C $XDG_CONFIG_HOME/mc'
alias duf='duf --only local'
alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'
alias fetch='fastfetch'

tempe () {
  cd "$(mktemp -d)"
  chmod -R 0700 .
  if [[ $# -eq 1 ]]; then
    \mkdir -p "$1"
    cd "$1"
    chmod -R 0700 .
  fi
}

boop () {
  local last="$?"
  if [[ "$last" == '0' ]]; then
    sfx good
  else
    sfx bad
  fi
  $(exit "$last")
}

__ZSHPROXY_HTTP="${__ZSHPROXY_HTTP:-nas.uglyboy.cn:50172}"

proxy () {
	# http_proxy
	export http_proxy="${__ZSHPROXY_HTTP}"
	export HTTP_PROXY="${__ZSHPROXY_HTTP}"
	# https_proxy
	export https_proxy="${__ZSHPROXY_HTTP}"
	export HTTPS_PROXY="${__ZSHPROXY_HTTP}"
    echo "HTTP Proxy On."
}

# cmd: unset proxy
noproxy () {
	unset http_proxy
	unset HTTP_PROXY
	unset https_proxy
	unset HTTPS_PROXY
    echo "HTTP Proxy Off."
}

# cmd: show proxy
show_proxy () {
    echo "http_proxy: $__ZSHPROXY_HTTP"
    echo "https_proxy: $__ZSHPROXY_HTTP"
}
