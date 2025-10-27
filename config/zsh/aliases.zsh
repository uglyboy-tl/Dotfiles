# alias definitions
alias size='f(){ sudo du -h --max-depth=1 $1 | sort -hr; }; f'
alias runv='source .venv/bin/activate'
alias mc='mc -C $XDG_CONFIG_HOME/mc'

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
