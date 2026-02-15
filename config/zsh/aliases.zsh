alias size='f(){ sudo du -h --max-depth=1 $1 | sort -hr; }; f'
alias runv='source .venv/bin/activate'
alias duf='duf --only local'
alias wget='wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'
alias fetch='fastfetch'

__ZSHPROXY_HTTP="${__ZSHPROXY_HTTP:-192.168.0.100:50171}"

proxy () {
	# http_proxy
	export http_proxy="${__ZSHPROXY_HTTP}"
	export HTTP_PROXY="${__ZSHPROXY_HTTP}"
	# https_proxy
	export https_proxy="${__ZSHPROXY_HTTP}"
	export HTTPS_PROXY="${__ZSHPROXY_HTTP}"
	# no_proxy
	export no_proxy="localhost,127.0.0.1,192.168.*,10.*,::1"
	export NO_PROXY="localhost,127.0.0.1,192.168.*,10.*,::1"
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
