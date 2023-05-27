#!/bin/bash

# debug output and exit on error or use of undeclared variable or pipe error:
set -o xtrace -o errtrace -o errexit -o nounset -o pipefail

version="$(curl --location --head https://github.com/gokcehan/lf/releases/latest | grep -i location: | sed 's/^.*\/tag\/\([^\/]*\)\r$/\1/')"
filename="lf-linux-amd64.tar.gz"
uri_to_download="https://github.com/gokcehan/lf/releases/download/${version}/${filename}"

# set proxy
export http_proxy="http://192.168.0.100:20171"
export https_proxy="http://192.168.0.100:20171"
curl --fail --show-error --location "$uri_to_download" |
  tar -xz -C /tmp/
mv --force /tmp/lf "${HOME}/.local/bin/lf" && 
  chmod a+x "${HOME}/.local/bin/lf"

curl --fail --show-error --location https://raw.githubusercontent.com/gokcehan/lf/master/lf.1 --output "$HOME"/.local/share/man/man1/lf.1

# stop proxy
unset http_proxy
unset https_proxy

if [ ! -x "${HOME}/.local/bin/lf" ]; then
    echo '"lf" was not successfully installed!' >&2
    # DISPLAY=:0 notify-send --urgency=critical "Failed updating lf!
      # Run $0 to check."
    exit 2
fi
