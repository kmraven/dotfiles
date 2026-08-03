# Keep non-interactive shells portable and fast.
export GOPATH="${GOPATH:-$HOME/go}"

typeset -U path PATH
path=(
    "$HOME/.local/bin"
    "$HOME/bin"
    "$GOPATH/bin"
    /usr/local/bin
    /usr/local/sbin
    $path
)

# MacPorts is only present on macOS. GNU utilities take precedence when installed.
if [[ "$OSTYPE" == darwin* ]]; then
    path=(
        /opt/local/libexec/gnubin
        /opt/local/bin
        /opt/local/sbin
        $path
    )
fi

export PATH
